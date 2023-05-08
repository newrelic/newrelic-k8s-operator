/*
Copyright 2023.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package controllers

import (
	"context"
	"runtime"
	"time"

	"github.com/operator-framework/helm-operator-plugins/pkg/annotation"
	"github.com/operator-framework/helm-operator-plugins/pkg/reconciler"
	k8sruntime "k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/schema"
	ctrl "sigs.k8s.io/controller-runtime"
	"sigs.k8s.io/controller-runtime/pkg/client"

	newrelicv1alpha1 "github.com/newrelic/newrelic-k8s-operator/api/v1alpha1"
)

var (
	maxConcurrentReconciles = runtime.NumCPU()
	reconcilePeriod         = time.Minute
	ctrlLog                 = ctrl.Log.WithName("controller")

	newRelicRepo  = "https://helm-charts.newrelic.com"
	newRelicChart = "nri-bundle"
	crdGroup      = "newrelic.com"
	crdVersion    = "v1alpha1"
	crdKind       = "NRIBundle"
)

// NewRelicReconciler reconciles a Monitor object
type NewRelicReconciler struct {
	client.Client
	Scheme *k8sruntime.Scheme

	// The controller-runtime manager for managing the current nri-bundle version.
	helmMgr *ctrl.Manager
	// Channel used as the signal for the helmManager to stop running.
	helmMgrCancel context.CancelFunc
}

//+kubebuilder:rbac:groups=newrelic.com,resources=monitors,verbs=get;list;watch;create;update;patch;delete
//+kubebuilder:rbac:groups=newrelic.com,resources=monitors/status,verbs=get;update;patch
//+kubebuilder:rbac:groups=newrelic.com,resources=monitors/finalizers,verbs=update

// Reconcile is part of the main kubernetes reconciliation loop which aims to
// move the current state of the cluster closer to the desired state.
// It currently checks the user's desired version of nri-bundle, and starts/restarts the proper HelmChart reconciler
// accordingly.
func (r *NewRelicReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
	var nr newrelicv1alpha1.Monitor
	if err := r.Get(ctx, req.NamespacedName, &nr); err != nil {
		ctrlLog.Info("NewRelic CRD deleted, running deletion")
		return r.reconcileDelete()
	}

	nr, result, err := r.reconcile(nr)

	// Update status after reconciliation.
	if updateStatusErr := r.patchStatus(ctx, &nr); updateStatusErr != nil {
		ctrlLog.Info("Failed to patch status")
		return ctrl.Result{Requeue: true}, updateStatusErr
	}
	return result, err
}

func (r *NewRelicReconciler) reconcile(nr newrelicv1alpha1.Monitor) (newrelicv1alpha1.Monitor, ctrl.Result, error) {
	// Check if the NRIBundle version is mismatched.
	if nr.Status.Version != nr.Spec.Version || r.helmMgr == nil {
		r.stopHelmManager()
		err := r.startHelmManager(nr)
		if err != nil {
			return nr, ctrl.Result{Requeue: true}, err
		}

		nr.Status.Version = nr.Spec.Version
	}

	// If status and spec versions match, nothing to do.
	return nr, ctrl.Result{Requeue: false}, nil
}

func (r *NewRelicReconciler) patchStatus(ctx context.Context, nr *newrelicv1alpha1.Monitor) error {
	ctrlLog.Info("Patching status")
	latest := &newrelicv1alpha1.Monitor{}
	if err := r.Client.Get(ctx, client.ObjectKeyFromObject(nr), latest); err != nil {
		return err
	}
	patch := client.MergeFrom(latest.DeepCopy())
	latest.Status = nr.Status
	return r.Client.Status().Patch(ctx, latest, patch)
}

func (r *NewRelicReconciler) reconcileDelete() (ctrl.Result, error) {
	// Deleting the NewRelic CRD stops the HelmManager.
	r.stopHelmManager()

	return ctrl.Result{}, nil
}

func (r *NewRelicReconciler) startHelmManager(nr newrelicv1alpha1.Monitor) error {
	// Load HelmChart for version.
	chart, err := LoadChart(newRelicRepo, newRelicChart, nr.Spec.Version)
	if err != nil {
		ctrlLog.Error(err, "Unable to load chart")
		return err
	}
	if nr.Spec.Version == "" {
		nr.Spec.Version = chart.Metadata.Version
		err = r.Client.Update(context.Background(), &nr)
		if err != nil {
			ctrlLog.Error(err, "Failed to update version in spec")
			return err
		}
	}

	mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
		Scheme:                 r.Scheme,
		MetricsBindAddress:     "0",
		Port:                   9444,
		HealthProbeBindAddress: "0",
	})
	if err != nil {
		ctrlLog.Error(err, "unable to start manager")
		return err
	}

	gvk := schema.GroupVersionKind{
		Group:   crdGroup,
		Version: crdVersion,
		Kind:    crdKind,
	}

	helmReconciler, err := reconciler.New(
		reconciler.WithChart(*chart),
		reconciler.WithGroupVersionKind(gvk),
		reconciler.WithMaxConcurrentReconciles(maxConcurrentReconciles),
		reconciler.WithReconcilePeriod(reconcilePeriod),
		reconciler.SkipDependentWatches(true),
		reconciler.WithInstallAnnotations(annotation.DefaultInstallAnnotations...),
		reconciler.WithUpgradeAnnotations(annotation.DefaultUpgradeAnnotations...),
		reconciler.WithUninstallAnnotations(annotation.DefaultUninstallAnnotations...),
	)
	if err != nil {
		ctrlLog.Error(err, "unable to create helm reconciler", "controller", "Helm")
		return err
	}
	if err := helmReconciler.SetupWithManager(mgr); err != nil {
		ctrlLog.Error(err, "unable to create controller", "controller", "Helm")
		return err
	}

	r.helmMgr = &mgr
	cancelCtx, cancel := context.WithCancel(context.Background())
	r.helmMgrCancel = cancel
	go func() {
		ctrlLog.Info("starting helm manager")
		if err := mgr.Start(cancelCtx); err != nil {
			ctrlLog.Error(err, "problem running helm manager")
		}
	}()

	return nil
}

func (r *NewRelicReconciler) stopHelmManager() {
	if r.helmMgr == nil {
		return
	}

	ctrlLog.Info("Stopping HelmManager")
	r.helmMgrCancel()
	r.helmMgr = nil
}

// Stop should be called whenever the reconciler exits, to ensure all subprocesses are also halted.
func (r *NewRelicReconciler) Stop() {
	r.stopHelmManager()
}

// SetupWithManager sets up the controller with the Manager.
func (r *NewRelicReconciler) SetupWithManager(mgr ctrl.Manager) error {
	return ctrl.NewControllerManagedBy(mgr).
		For(&newrelicv1alpha1.Monitor{}).
		Complete(r)
}
