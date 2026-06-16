#!/usr/bin/env bash
set -euo pipefail

# --- Configuration ---
CLUSTER_NAME=""
K8S_VERSION=""
LICENSE_KEY=""
RUN_TESTS=""

OPERATOR_NS="newrelic-k8s-operator"
OPERATOR_IMAGE="e2e/newrelic-k8s-operator:e2e"
OPERATOR_DEPLOY="newrelic-k8s-operator-controller-manager"

SCRIPT_PATH=$(dirname "$0")
REPO_ROOT=$(realpath "$SCRIPT_PATH/../..")

# Timeouts (seconds). These are generous to tolerate slow Helm chart downloads.
OPERATOR_READY_TIMEOUT=300   # operator pod reaches Ready
RECONCILE_TIMEOUT=180        # operator downloads nri-bundle chart + reconciles Monitor
HELM_DEPLOY_TIMEOUT=300      # nri-bundle Helm release reaches deployed status
WORKLOAD_TIMEOUT=300         # nri-bundle workloads (DaemonSets etc.) are created

# Test result counters
PASS=0
FAIL=0

# --- Helpers ---

function pass() { echo "  ✅ $1"; PASS=$((PASS + 1)); }
function fail() { echo "  ❌ $1" >&2; FAIL=$((FAIL + 1)); }

# poll_until <description> <timeout_secs> <shell_expression>
# Evaluates <shell_expression> every 5 seconds until it exits 0 or the timeout
# is exceeded. Redirects stdout/stderr from the expression to /dev/null.
function poll_until() {
    local description="$1"
    local timeout_secs="$2"
    local cmd="$3"
    local deadline=$(( $(date +%s) + timeout_secs ))

    echo "  ⏳ Polling: ${description} (timeout: ${timeout_secs}s)"
    while [[ $(date +%s) -lt $deadline ]]; do
        if eval "$cmd" > /dev/null 2>&1; then
            return 0
        fi
        sleep 5
    done
    echo "  ⏰ Timed out after ${timeout_secs}s: ${description}" >&2
    return 1
}

function check_dependencies() {
    local missing=()
    for cmd in minikube kubectl helm docker jq; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "❌ Missing required tools: ${missing[*]}" >&2
        exit 1
    fi
}

# --- Argument parsing ---

function parse_args() {
    local total_args=$#
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                help
                exit 0
                ;;
            --k8s_version)
                shift; K8S_VERSION="$1"
                ;;
            --license_key)
                shift; LICENSE_KEY="$1"
                ;;
            --run_tests)
                RUN_TESTS="true"
                ;;
            -*|--*|*)
                echo "❌ Unknown argument: $1" >&2
                help
                exit 1
                ;;
        esac
        shift
    done

    if [[ $total_args -lt 4 ]]; then
        help
        exit 0
    fi

    if [[ -z "$K8S_VERSION" || -z "$LICENSE_KEY" ]]; then
        echo "❌ Error: --k8s_version and --license_key are required." >&2
        help
        exit 1
    fi
}

function help() {
    cat <<END
Usage:
  ${0##*/}  --k8s_version <cluster_version>
            --license_key <license_key>
            [--run_tests]

  --k8s_version  Kubernetes version for the minikube cluster (e.g. v1.28.0)
  --license_key  New Relic INGEST - LICENSE key
  --run_tests    If set, runs tests after cluster setup and tears down cluster on completion.
                 If unset, the cluster is left running and tests are not run.
END
}

# --- Cluster setup ---

function create_cluster() {
    check_dependencies

    echo "🚀 === Setup ==="
    minikube delete --all > /dev/null 2>&1 || true
    CLUSTER_NAME="$(date "+%Y-%m-%d-%H-%M-%S")-e2e-tests"

    echo "🏗️  Creating cluster: ${CLUSTER_NAME} (k8s ${K8S_VERSION})"
    minikube start \
        --container-runtime=containerd \
        --kubernetes-version="${K8S_VERSION}" \
        --profile "${CLUSTER_NAME}"

    echo "🔨 Building operator image: ${OPERATOR_IMAGE}"
    DOCKER_BUILDKIT=1 docker build \
        --tag "${OPERATOR_IMAGE}" \
        "${REPO_ROOT}" \
        --quiet

    echo "📦 Loading image into cluster"
    minikube image load "${OPERATOR_IMAGE}" --profile "${CLUSTER_NAME}"

    echo "📡 Adding Helm repositories"
    helm repo add newrelic https://helm-charts.newrelic.com > /dev/null
    helm repo update > /dev/null

    echo "⚙️ Installing operator via Helm"
    helm upgrade --install newrelic-k8s-operator "${REPO_ROOT}/charts/newrelic-k8s-operator" \
        --namespace "${OPERATOR_NS}" \
        --create-namespace \
        --set "global.licenseKey=${LICENSE_KEY}" \
        --set "global.cluster=e2e-tests" \
        --set "images.operator.repository=e2e/newrelic-k8s-operator" \
        --set "images.operator.tag=e2e" \
        --set "images.operator.pullPolicy=Never" \
        --wait \
        --timeout "${OPERATOR_READY_TIMEOUT}s"

    echo "✅ Setup complete"
}

# --- Tests ---

function run_tests() {
    echo ""
    echo "🧪 === Running E2E Tests ==="

    test_operator_ready
    test_monitor_version_resolved
    test_nribundle_helm_release_deployed
    test_nri_infrastructure_deployed
    test_monitor_status_matches_helm_version

    echo ""
    echo "📊 === Results: ${PASS} passed, ${FAIL} failed ==="
    [[ $FAIL -eq 0 ]]
}

# Test 1: Operator deployment reaches Available and its pod passes the readiness probe.
# This validates that the operator started, connected to the API server, and is healthy.
function test_operator_ready() {
    echo ""
    echo "🔍 Test: Operator deployment is available"

    if kubectl rollout status "deployment/${OPERATOR_DEPLOY}" \
            -n "${OPERATOR_NS}" \
            --timeout="${OPERATOR_READY_TIMEOUT}s"; then
        pass "Operator deployment rolled out successfully"
    else
        fail "Operator deployment did not complete rollout within ${OPERATOR_READY_TIMEOUT}s"
        kubectl get events -n "${OPERATOR_NS}" --sort-by='.lastTimestamp' | tail -20 >&2 || true
        return
    fi

    if kubectl wait pod \
            -n "${OPERATOR_NS}" \
            -l "control-plane=controller-manager" \
            --for=condition=Ready \
            --timeout="${OPERATOR_READY_TIMEOUT}s"; then
        pass "Operator pod is Ready (readiness probe passed)"
    else
        fail "Operator pod did not reach Ready state within ${OPERATOR_READY_TIMEOUT}s"
        kubectl describe pod -n "${OPERATOR_NS}" -l "control-plane=controller-manager" >&2 || true
    fi
}

# Test 2: Monitor.status.version is automatically populated.
# When spec.version is empty, the operator resolves the latest nri-bundle chart version
# and writes it back to both spec and status. A non-empty status.version proves the
# reconciliation loop ran successfully and reached the Helm chart repository.
function test_monitor_version_resolved() {
    echo ""
    echo "🔍 Test: Monitor status.version is auto-resolved (reconciliation loop ran)"

    if poll_until "Monitor status.version to be non-empty" "$RECONCILE_TIMEOUT" \
            'kubectl get monitor newrelic -o jsonpath="{.status.version}" 2>/dev/null | grep -q .'; then
        local version
        version=$(kubectl get monitor newrelic -o jsonpath='{.status.version}')
        pass "Monitor status.version resolved to: ${version}"
    else
        fail "Monitor status.version was not populated after ${RECONCILE_TIMEOUT}s"
        kubectl get monitor newrelic -o yaml >&2 || true
        kubectl logs "deployment/${OPERATOR_DEPLOY}" -n "${OPERATOR_NS}" --tail=50 >&2 || true
    fi
}

# Test 3: The inner Helm manager created an nri-bundle release.
# The Helm operator plugin creates a Helm release for the NRIBundle CR named 'nribundle'.
# We check that the release exists (in any state) to confirm the operator initiated the
# install. We do not require 'deployed' status because the helm-operator-plugins waits for
# all pods to be ready before finalizing the release, and pod readiness depends on the
# license key being valid and network connectivity to New Relic — both outside our control
# in a basic e2e run.
function test_nribundle_helm_release_deployed() {
    echo ""
    echo "🔍 Test: nri-bundle Helm release is created by the operator"

    # helm list -o json returns [] when no releases match; jq -e 'length > 0' exits 0
    # only when there is at least one release, regardless of its status.
    if poll_until "nribundle Helm release to be created" "$HELM_DEPLOY_TIMEOUT" \
            "helm list -n ${OPERATOR_NS} -o json --filter '^nribundle\$' 2>/dev/null | jq -e 'length > 0'"; then
        local helm_json chart_info status
        helm_json=$(helm list -n "${OPERATOR_NS}" -o json --filter '^nribundle$')
        chart_info=$(echo "$helm_json" | jq -r '.[0].chart')
        status=$(echo "$helm_json" | jq -r '.[0].status')
        pass "nribundle Helm release exists (chart: ${chart_info}, status: ${status})"
    else
        fail "nribundle Helm release was not created after ${HELM_DEPLOY_TIMEOUT}s"
        helm list -n "${OPERATOR_NS}" >&2 || true
        kubectl get events -n "${OPERATOR_NS}" --sort-by='.lastTimestamp' | tail -20 >&2 || true
    fi
}

# Test 4: nri-bundle created a kubelet DaemonSet.
# With the default chart values (newrelic-infrastructure.enabled=true), the nri-bundle
# Helm release must create a DaemonSet that collects kubelet metrics. We check for
# existence only (not pod readiness) to avoid a dependency on New Relic connectivity.
# The DaemonSet name differs by chart generation:
#   nri-bundle <6.x:  newrelic-infrastructure
#   nri-bundle >=6.x: <release>-nrk8s-kubelet  (e.g. nribundle-nrk8s-kubelet)
function test_nri_infrastructure_deployed() {
    echo ""
    echo "🔍 Test: nri-bundle deployed a kubelet DaemonSet"

    if poll_until "nri-bundle kubelet DaemonSet to be created" "$WORKLOAD_TIMEOUT" \
            "kubectl get daemonsets -n ${OPERATOR_NS} --no-headers 2>/dev/null | grep -qE 'nrk8s-kubelet|newrelic-infrastructure'"; then
        local ds_name
        ds_name=$(kubectl get daemonsets -n "${OPERATOR_NS}" --no-headers \
            | grep -E 'nrk8s-kubelet|newrelic-infrastructure' | awk '{print $1}')
        pass "kubelet DaemonSet exists: ${ds_name}"
    else
        fail "nri-bundle kubelet DaemonSet was not created after ${WORKLOAD_TIMEOUT}s"
        kubectl get all -n "${OPERATOR_NS}" >&2 || true
    fi
}

# Test 5: Monitor.status.version matches the deployed Helm chart version.
# The operator's reconcile loop sets status.version to the resolved chart version.
# Cross-checking this against the actual Helm release confirms status is kept in sync.
function test_monitor_status_matches_helm_version() {
    echo ""
    echo "🔍 Test: Monitor status.version matches deployed Helm chart version"

    local monitor_version helm_json helm_chart helm_version
    monitor_version=$(kubectl get monitor newrelic -o jsonpath='{.status.version}' 2>/dev/null || echo "")

    if [[ -z "$monitor_version" ]]; then
        fail "Monitor status.version is empty - skipping version consistency check"
        return
    fi

    helm_json=$(helm list -n "${OPERATOR_NS}" -o json --filter '^nribundle$' 2>/dev/null || echo "[]")
    helm_chart=$(echo "$helm_json" | jq -r '.[0].chart // empty')
    helm_version="${helm_chart#nri-bundle-}"

    if [[ -z "$helm_version" ]]; then
        fail "Could not determine nribundle Helm release chart version - is the release deployed?"
        return
    fi

    if [[ "$monitor_version" == "$helm_version" ]]; then
        pass "Monitor status.version (${monitor_version}) matches Helm chart version (${helm_version})"
    else
        fail "Version mismatch: Monitor status.version=${monitor_version}, Helm chart version=${helm_version}"
    fi
}

# --- Teardown ---

function teardown() {
    echo ""
    echo "🧹 === Teardown ==="
    if [[ -n "$CLUSTER_NAME" ]]; then
        minikube delete --profile "${CLUSTER_NAME}" > /dev/null 2>&1 || true
        echo "🗑️Cluster ${CLUSTER_NAME} deleted"
    fi
}

# --- Entrypoint ---

function main() {
    parse_args "$@"
    create_cluster
    if [[ "$RUN_TESTS" == "true" ]]; then
        # Use set +e so teardown always runs regardless of test failures.
        set +e
        run_tests
        test_exit_code=$?
        set -e
        teardown
        exit $test_exit_code
    fi
}

main "$@"
