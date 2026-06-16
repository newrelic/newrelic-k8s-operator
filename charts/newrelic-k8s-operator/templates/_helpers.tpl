{{/*
Build the fully-qualified operator image reference.
Registry precedence: images.operator.registry > global.images.registry > (none)
Tag defaults to .Chart.AppVersion when images.operator.tag is empty.
*/}}
{{- define "newrelic-k8s-operator.images.operator.image" -}}
{{- $registry := .Values.images.operator.registry | default .Values.global.images.registry -}}
{{- $repository := .Values.images.operator.repository -}}
{{- $tag := .Values.images.operator.tag | default .Chart.AppVersion -}}
{{- if $registry -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- else -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end -}}
{{- end -}}