# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

## v0.9.0 - 2026-06-22

### 🚀 Enhancements
- BREAKING Change: Added image configuration options. You may need to update your values file. @dbudziwojski [#143](https://github.com/newrelic/newrelic-k8s-operator/pull/143)

### ⛓️ Dependencies
- Updated kubernetes monorepo to v0.36.2
- Updated helm.sh/helm/v3 to v3.21.2

## v0.8.2 - 2026-06-15

### ⛓️ Dependencies
- Updated source
- Updated alpine to v3.24
- Updated github.com/onsi/ginkgo/v2 to v2.31.0 - [Changelog 🔗](https://github.com/onsi/ginkgo/releases/tag/v2.31.0)
- Updated helm.sh/helm/v3 to v3.21.1
- Updated github.com/onsi/gomega to v1.42.0 - [Changelog 🔗](https://github.com/onsi/gomega/releases/tag/v1.42.0)

## v0.8.1 - 2026-06-08

### ⛓️ Dependencies
- Updated kubernetes monorepo to v0.36.1

## v0.8.0 - 2026-06-01

### 🚀 Enhancements
- Enable automatically weekly releases @dbudziwojski [#139](https://github.com/newrelic/newrelic-k8s-operator/pull/140)
- Add E2E tests @dbudziwojski [#139](https://github.com/newrelic/newrelic-k8s-operator/pull/140)

### 🐞 Bug fixes
- Fix issues with reconciliation loop + metrics namespace overlap. @dbudziwojski [#139](https://github.com/newrelic/newrelic-k8s-operator/pull/139)

## v0.7.1 - 2026-05-25

### ⛓️ Dependencies
- Upgraded github.com/containerd/containerd from 1.7.30 to 1.7.32 - [Changelog 🔗](https://github.com/containerd/containerd/releases/tag/v1.7.32)

## v0.7.0 - 2026-05-21

### dependency
- Update dependencies to latest [#126](https://github.com/newrelic/newrelic-k8s-operator/pull/126)

### 🛡️ Security notices
- Improve GHA security permissions @dbudziwojski [#135](https://github.com/newrelic/newrelic-k8s-operator/pull/135)

### ⛓️ Dependencies
- Updated source

## v0.6.1 - 2023-12-11

### ⛓️ Dependencies
- Updated alpine to v3.19.0
- Updated go to v1.21.5

## v0.6.0 - 2023-12-06

### 🚀 Enhancements
- Update reusable workflow dependency by @juanjjaramillo [#93](https://github.com/newrelic/newrelic-k8s-operator/pull/93)

### ⛓️ Dependencies
- Updated github.com/onsi/ginkgo/v2 to v2.13.2 - [Changelog 🔗](https://github.com/onsi/ginkgo/releases/tag/v2.13.2)

## v0.5.0 - 2023-11-13

### 🚀 Enhancements
- Add full k8s 1.28 support by @svetlanabrennan in [#89](https://github.com/newrelic/newrelic-k8s-operator/pull/89)

### ⛓️ Dependencies
- Updated github.com/onsi/gomega to v1.30.0 - [Changelog 🔗](https://github.com/onsi/gomega/releases/tag/v1.30.0)
- Updated github.com/onsi/ginkgo/v2 to v2.13.1 - [Changelog 🔗](https://github.com/onsi/ginkgo/releases/tag/v2.13.1)

## v0.4.0 - 2023-10-30

### 🛡️ Security notices
- Operator gets New Relic License Key from a secret instead of NRIBundle CR.

### 🚀 Enhancements
- Make `licenseKey` parameter optional in the Helm Chart.

### 🐞 Bug fixes
- Do not set the version for the Monitor CR if its input value in the Helm Chart is empty.

### ⛓️ Dependencies
- Updated github.com/onsi/gomega to v1.29.0 - [Changelog 🔗](https://github.com/onsi/gomega/releases/tag/v1.29.0)

## v0.3.0 - 2023-10-23

### ⛓️ Dependencies
- Updated github.com/onsi/gomega to v1.28.1 - [Changelog 🔗](https://github.com/onsi/gomega/releases/tag/v1.28.1)
- Upgraded golang.org/x/net from 0.14.0 to 0.17.0
- Upgraded github.com/cyphar/filepath-securejoin from 0.2.3 to 0.2.4 - [Changelog 🔗](https://github.com/cyphar/filepath-securejoin/releases/tag/v0.2.4)

## v0.2.1 - 2023-10-16

### ⛓️ Dependencies
- Updated github.com/onsi/ginkgo/v2 to v2.13.0 - [Changelog 🔗](https://github.com/onsi/ginkgo/releases/tag/v2.13.0)

## v0.2.0 - 2023-10-07

### 🚀 Enhancements
- Sync versions between app image and Helm chart to ease customer inception by @juanjjaramillo in [#73](https://github.com/newrelic/newrelic-k8s-operator/pull/73)

## v0.1.0 - 2023-10-07

### 🚀 Enhancements
- Enable automatic release by @juanjjaramillo in [#69](https://github.com/newrelic/newrelic-k8s-operator/pull/69)
- Add 'changelog' workflow by @juanjjaramillo in [#68](https://github.com/newrelic/newrelic-k8s-operator/pull/68)
- Add pull request template by @juanjjaramillo in [#67](https://github.com/newrelic/newrelic-k8s-operator/pull/67)
- Introduce CHANGELOG.md by @juanjjaramillo in [#66](https://github.com/newrelic/newrelic-k8s-operator/pull/66)
- adding the `patch` operation for `operators.coreos.com` by @AmitBenAmi in [#56](https://github.com/newrelic/newrelic-k8s-operator/pull/56)

### ⛓️ Dependencies
- Updated sigs.k8s.io/controller-runtime to v0.14.6
- Updated github.com/onsi/gomega
- Updated alpine to v3.18.4
- Updated github.com/onsi/ginkgo/v2 to v2.12.1 - [Changelog 🔗](https://github.com/onsi/ginkgo/releases/tag/v2.12.1)
- Updated golang to v1.20
- Updated golang version
- Upgraded github.com/docker/distribution from 2.8.1+incompatible to 2.8.2+incompatible

## v0.0.1 - 2023-05-08

### 🚀 Enhancements
- Initial operator release
