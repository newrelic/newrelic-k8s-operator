# newrelic-k8s-operator

![Version: 0.6.0](https://img.shields.io/badge/Version-0.6.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 0.6.0](https://img.shields.io/badge/AppVersion-0.6.0-informational?style=flat-square)

A Helm chart for New Relic's Kubernetes operator.

**Homepage:** <https://github.com/newrelic/newrelic-k8s-operator>

# Helm installation

You can install this chart using directly from this repository or by adding the Helm repository:

```shell
helm repo add newrelic https://helm-charts.newrelic.com && helm repo update
helm upgrade --install newrelic/newrelic-k8s-operator -f your-custom-values.yaml
```

## Source Code

* <https://github.com/newrelic/newrelic-k8s-operator/>

## Values

The values for the chart follow the values in the [nri-bundle chart](https://github.com/newrelic/helm-charts/tree/master/charts/nri-bundle).

## Maintainers

* [aimichelle](https://github.com/aimichelle)
* [htroisi](https://github.com/htroisi)
* [vihangm](https://github.com/vihangm)
