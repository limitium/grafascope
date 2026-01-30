
{{- define "victoriametrics.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "victoriametrics.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" (include "victoriametrics.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "victoriametrics.labels" -}}
app.kubernetes.io/name: {{ include "victoriametrics.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "victoriametrics.selectorLabels" -}}
app.kubernetes.io/name: {{ include "victoriametrics.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "victoria.name" -}}
{{- include "victoriametrics.name" . -}}
{{- end -}}

{{- define "victoria.fullname" -}}
{{- include "victoriametrics.fullname" . -}}
{{- end -}}

{{- define "victoria.labels" -}}
{{- include "victoriametrics.labels" . -}}
{{- end -}}

{{- define "victoria.selectorLabels" -}}
{{- include "victoriametrics.selectorLabels" . -}}
{{- end -}}

{{- define "victoria-metrics.globalPath" -}}
{{- default "" (index .Values.global.paths "victoriaMetrics") -}}
{{- end -}}

{{- define "victoria-metrics.globalPort" -}}
{{- default "" (index .Values.global.ports "victoriaMetrics") -}}
{{- end -}}
