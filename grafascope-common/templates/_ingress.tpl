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
  rules:
    - host: {{ required "global.domain is required" $ctx.Values.global.domain | quote }}
      http:
        paths:
          - path: {{ required "ingress path is required" .path | quote }}
            pathType: {{ default "Prefix" .pathType }}
            backend:
              service:
                name: {{ .serviceName }}
                port:
                  number: {{ .servicePort }}
  {{- if .ingress.tls }}
  tls:
    {{- toYaml .ingress.tls | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}

