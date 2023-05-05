<a href="https://opensource.newrelic.com/oss-category/#community-project"><picture><source media="(prefers-color-scheme: dark)" srcset="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/dark/Community_Project.png"><source media="(prefers-color-scheme: light)" srcset="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/Community_Project.png"><img alt="New Relic Open Source community project banner." src="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/Community_Project.png"></picture></a>

# New Relic K8s Operator

This repository contains the source code for New Relic's K8s operator. The K8s operator helps users deploy and manage their deployment of [New Relic's K8s solution](https://github.com/newrelic/helm-charts/tree/master/charts/nri-bundle).

The K8s operator is built using Operator Framework's (Hybrid Helm Operator)[https://github.com/operator-framework/helm-operator-plugins].

## Table of contents

- [Table of contents](#table-of-contents)
- [Installation](#installation)
- [Helm chart](#helm-chart)
- [Development flow](#development-flow)
  - [Running locally](#running-locally)
- [Support](#support)
- [Contributing](#contributing)
- [License](#license)

## Installation

For installation instructions, refer to our (docs)[].

## Helm chart

You can install this chart using directly from this repository or by adding the Helm repository:

```shell
helm repo add newrelic https://helm-charts.newrelic.com && helm repo update
helm upgrade --install newrelic/newrelic-k8s-operator -f your-custom-values.yaml
```

For further information of the configuration needed for the chart just read the [chart's README](/charts/newrelic-k8s-operator/README.md).

## Development flow

This project uses a Makefile for the most common use cases.

When updating the NewRelic CRD, you should add or modify fields and types to `api/v1alpha1/newrelic_types.go`. After editing the file, make sure to run the following to update the CRD YAML and generated API files:

```shell
make manifests
make generate
```

To update the Helm charts templates, run:

```shell
make helm IMG=<registry>/newrelic-operator:<version>
```

### Running locally

The easiest way to get started is using the commands in the Makefile
and [Minikube](https://kubernetes.io/docs/setup/learning-environment/minikube/).

Follow these steps to run this project:

 - Ensure Minikube is running
```sh
$ minikube status
host: Running
kubelet: Running
apiserver: Running
kubectl: Correctly Configured: pointing to minikube-vm at 192.168.x.x
```

```shell
docker build -t <registry>/newrelic-operator:0.0.1 .
docker push <registry>/newrelic-operator:0.0.1
make deploy <registry>/newrelic-operator:0.0.1
```

This will deploy the necessary service accounts, RBAC policies, and deployment necessary for the operator to run. The operator will be running in the `newrelic-operator-system` namespace.
You can then deploy the sample CRDs. Before doing so, make sure to update the licenseKey with your own in `config/samples/minimal_nribundle.yaml`:

```shell
kubectl apply -f config/samples/newrelic_v1alpha1_newrelic.yaml
kubectl apply -f config/samples/minimal_nribundle.yaml
```

To clean up:

```shell
make undeploy
```

## Support

New Relic hosts and moderates an online forum where you can interact with New Relic employees as well as other customers to get help and share best practices. Like all official New Relic open source projects, there's a related Community topic in the New Relic Explorers Hub. You can find this project's topic/threads here:

>Add the url for the support thread here: discuss.newrelic.com

## Contribute

We encourage your contributions to improve newrelic-k8s-operator! Keep in mind that when you submit your pull request, you'll need to sign the CLA via the click-through using CLA-Assistant. You only have to sign the CLA one time per project.

If you have any questions, or to execute our corporate CLA (which is required if your contribution is on behalf of a company), drop us an email at opensource@newrelic.com.

**A note about vulnerabilities**

As noted in our [security policy](../../security/policy), New Relic is committed to the privacy and security of our customers and their data. We believe that providing coordinated disclosure by security researchers and engaging with the security community are important means to achieve our security goals.

If you believe you have found a security vulnerability in this project or any of New Relic's products or websites, we welcome and greatly appreciate you reporting it to New Relic through [HackerOne](https://hackerone.com/newrelic).

If you would like to contribute to this project, review [these guidelines](./CONTRIBUTING.md).

To all contributors, we thank you!  Without your contribution, this project would not be what it is today.

## License
newrelic-k8s-operator is licensed under the [Apache 2.0](http://apache.org/licenses/LICENSE-2.0.txt) License.
newrelic-k8s-operator also eses source code from third-party libraries. You can find full details on which libraries are used and the terms under which they are licensed in the third-party notices document.
