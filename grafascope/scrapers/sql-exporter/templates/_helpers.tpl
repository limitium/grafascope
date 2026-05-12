{{- define "sql-exporter.name" -}}
{{- if .Values.nameOverride -}}
{{- .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- "sql-exporter" -}}
{{- end -}}
{{- end -}}

{{- define "sql-exporter.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" (include "sql-exporter.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "sql-exporter.labels" -}}
app.kubernetes.io/name: {{ include "sql-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{- define "sql-exporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sql-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "sql-exporter.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "sql-exporter.fullname" .) .Values.serviceAccount.name -}}
{{- else if .Values.serviceAccount.name -}}
{{- .Values.serviceAccount.name -}}
{{- else -}}
{{- "" -}}
{{- end -}}
{{- end -}}

{{- define "sql-exporter.servicePort" -}}
{{- $p := .Values.service.port -}}
{{- if not $p -}}
{{- $p = 9399 -}}
{{- if and .Values.global .Values.global.ports -}}
{{- if hasKey .Values.global.ports "sql-exporter" -}}
{{- $p = index .Values.global.ports "sql-exporter" -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- $p -}}
{{- end -}}

{{- define "sql-exporter.oracleBootstrapMain" -}}
global:
  scrape_timeout: 30s
  scrape_timeout_offset: 500ms
  max_connections: 3
  max_idle_connections: 3

jobs:
  - job_name: oracle_targets
    collectors: [grafascope_oracle_custom]
    enable_ping: true
    static_configs:
      - targets:
          primary: "${ORACLE_DSN}"

collector_files:
  - "*.collector.yml"
{{- end -}}

{{- define "sql-exporter.oracleBootstrapCollector" -}}
collector_name: grafascope_oracle_custom
metrics:
  - metric_name: oracle_sql_exporter_probe
    type: gauge
    help: "Always 1 when Oracle accepts a trivial probe (FROM DUAL)."
    values: [v]
    query: |
      SELECT 1 AS v FROM DUAL
{{- end -}}
