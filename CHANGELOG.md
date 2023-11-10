# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

### enhancement
- Add full k8s 1.28 support by @svetlanabrennan

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
