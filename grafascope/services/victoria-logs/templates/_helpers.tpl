
{{- define "victorialogs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "victorialogs.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" (include "victorialogs.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "victorialogs.labels" -}}
app.kubernetes.io/name: {{ include "victorialogs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "victorialogs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "victorialogs.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "victoria.name" -}}
{{- include "victorialogs.name" . -}}
{{- end -}}

{{- define "victoria.fullname" -}}
{{- include "victorialogs.fullname" . -}}
{{- end -}}

{{- define "victoria.labels" -}}
{{- include "victorialogs.labels" . -}}
{{- end -}}

{{- define "victoria.selectorLabels" -}}
{{- include "victorialogs.selectorLabels" . -}}
{{- end -}}

{{- define "victoria-logs.globalPath" -}}
{{- $path := default "" (index .Values.global.paths "victoriaLogs") -}}
{{- include "grafascope.pathWithNamespace" (dict "path" $path "namespace" .Release.Namespace) -}}
{{- end -}}

{{- define "victoria-logs.globalPort" -}}
{{- default "" (index .Values.global.ports "victoriaLogs") -}}
{{- end -}}
