{{- define "grafascope.pathWithNamespace" -}}
{{- $path := .path | default "" -}}
{{- if not $path -}}
{{- "" -}}
{{- else -}}
{{- $ns := .namespace | default "" -}}
{{- if $ns -}}
{{- $p := trimSuffix "/" $path -}}
{{- printf "/%s%s" (trimPrefix "/" $ns) $p -}}
{{- else -}}
{{- $path -}}
{{- end -}}
{{- end -}}
{{- end -}}
