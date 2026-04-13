{{- define "grafascope.common.httpRoute" -}}
{{- $ctx := .context -}}
{{- $gw := $ctx.Values.global.gateway -}}
{{- if and $gw.enabled .httpRoute.enabled -}}
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: {{ .name }}
  labels:
    {{- .labels | nindent 4 }}
  {{- with .httpRoute.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  parentRefs:
    {{- range $gw.routes.parentRefs }}
    - name: {{ .name | quote }}
      {{- if .namespace }}
      namespace: {{ .namespace | quote }}
      {{- end }}
      {{- if .sectionName }}
      sectionName: {{ .sectionName | quote }}
      {{- end }}
    {{- end }}
  hostnames:
    {{- range $gw.routes.hostnames }}
    - {{ . | quote }}
    {{- end }}
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: {{ include "grafascope.pathWithNamespace" (dict "path" (required "httpRoute path is required" $.path) "namespace" $ctx.Release.Namespace) | quote }}
      {{- with .httpRoute.filters }}
      filters:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      backendRefs:
        - name: {{ $.serviceName }}
          port: {{ $.servicePort }}
      {{- with .httpRoute.timeouts }}
      timeouts:
        {{- toYaml . | nindent 8 }}
      {{- end }}
{{- end }}
{{- end }}
