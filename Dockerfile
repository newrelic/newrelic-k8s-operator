# Build the manager binary
FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS build

# Set by docker automatically
ARG TARGETOS TARGETARCH

ARG GOOS=$TARGETOS
ARG GOARCH=$TARGETARCH

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/

# Build
RUN CGO_ENABLED=0 go build -o manager main.go

FROM alpine:3.18.5
WORKDIR /app

RUN apk add --no-cache --upgrade ca-certificates
RUN addgroup -g 2000 newrelic-k8s-operator \
    && adduser -D -H -u 1000 -G newrelic-k8s-operator newrelic-k8s-operator
RUN mkdir -p /home/newrelic-k8s-operator/.cache/helm/repository
RUN chown newrelic-k8s-operator /home/newrelic-k8s-operator/.cache/helm/repository

USER newrelic-k8s-operator

COPY --chown=newrelic-k8s-operator:newrelic-k8s-operator --from=build /workspace/manager ./

ENTRYPOINT ["./manager"]
