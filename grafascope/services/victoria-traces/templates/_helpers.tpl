
{{- define "victoriatraces.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "victoriatraces.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" (include "victoriatraces.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "victoriatraces.labels" -}}
app.kubernetes.io/name: {{ include "victoriatraces.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "victoriatraces.selectorLabels" -}}
app.kubernetes.io/name: {{ include "victoriatraces.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "victoria.name" -}}
{{- include "victoriatraces.name" . -}}
{{- end -}}

{{- define "victoria.fullname" -}}
{{- include "victoriatraces.fullname" . -}}
{{- end -}}

{{- define "victoria.labels" -}}
{{- include "victoriatraces.labels" . -}}
{{- end -}}

{{- define "victoria.selectorLabels" -}}
{{- include "victoriatraces.selectorLabels" . -}}
{{- end -}}

{{- define "victoria-traces.globalPath" -}}
{{- $path := default "" (index .Values.global.paths "victoriaTraces") -}}
{{- include "grafascope.pathWithNamespace" (dict "path" $path "namespace" .Release.Namespace) -}}
{{- end -}}

{{- define "victoria-traces.globalPort" -}}
{{- default "" (index .Values.global.ports "victoriaTraces") -}}
{{- end -}}
