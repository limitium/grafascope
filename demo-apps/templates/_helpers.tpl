{{- define "demo.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "demo.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "demo.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "demo.labels" -}}
app.kubernetes.io/name: {{ include "demo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "demo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "demo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "demo.imageRepository" -}}
{{- $repo := trimPrefix "/" .repository -}}
{{- if and $.Values.global $.Values.global.image $.Values.global.image.registry }}
{{- $parts := splitList "/" $repo }}
{{- if gt (len $parts) 1 }}
{{- $first := index $parts 0 }}
{{- if or (contains "." $first) (contains ":" $first) (eq $first "localhost") }}
{{- $repo = join "/" (slice $parts 1) }}
{{- end }}
{{- end }}
{{- $repo = printf "%s/%s" (trimSuffix "/" $.Values.global.image.registry) (trimPrefix "/" $repo) }}
{{- end }}
{{- $repo -}}
{{- end -}}
