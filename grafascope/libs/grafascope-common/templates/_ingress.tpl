{{- define "grafascope.common.ingress" -}}
{{- $ctx := .context -}}
{{- if .ingress.enabled -}}
{{- $ann := (default dict .ingress.annotations) -}}
{{- if .rewrite.enabled -}}
{{- if not (hasKey $ann "nginx.ingress.kubernetes.io/use-regex") -}}
{{- $_ := set $ann "nginx.ingress.kubernetes.io/use-regex" "true" -}}
{{- end -}}
{{- if not (hasKey $ann "nginx.ingress.kubernetes.io/rewrite-target") -}}
{{- $_ := set $ann "nginx.ingress.kubernetes.io/rewrite-target" .rewrite.target -}}
{{- end -}}
{{- end -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ .name }}
  labels:
    {{- .labels | nindent 4 }}
  annotations:
    {{- toYaml $ann | nindent 4 }}
spec:
  ingressClassName: {{ .ingress.className }}
  {{- $hosts := $ctx.Values.global.hosts }}
  {{- if not $hosts }}
  {{- $hosts = list (required "global.domain is required" $ctx.Values.global.domain) }}
  {{- end }}
  rules:
    {{- range $host := $hosts }}
    {{- $hostName := $host }}
    {{- if kindIs "map" $host }}
    {{- $hostName = $host.host }}
    {{- end }}
    - host: {{ $hostName | quote }}
      http:
        paths:
          - path: {{ include "grafascope.pathWithNamespace" (dict "path" (required "ingress path is required" $.path) "namespace" $ctx.Release.Namespace) | quote }}
            pathType: {{ default "Prefix" $.pathType }}
            backend:
              service:
                name: {{ $.serviceName }}
                port:
                  number: {{ $.servicePort }}
    {{- end }}
  {{- if .ingress.tls }}
  tls:
    {{- toYaml .ingress.tls | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}

