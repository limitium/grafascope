{{- define "grafascope.pathWithNamespace" -}}
{{- $path := .path | default "" -}}
{{- if not $path -}}
{{- "" -}}
{{- else -}}
{{- $ns := .namespace | default "" -}}
{{- if $ns -}}
{{- $nsPrefix := printf "/%s" (trimPrefix "/" $ns) -}}
{{- $already := false -}}
{{- if hasPrefix $path $nsPrefix -}}
{{- $rest := trimPrefix $nsPrefix $path -}}
{{- if or (eq $rest "") (hasPrefix $rest "/") -}}
{{- $already = true -}}
{{- end -}}
{{- end -}}
{{- if $already -}}
{{- $path -}}
{{- else -}}
{{- $p := trimSuffix "/" $path -}}
{{- printf "/%s%s" (trimPrefix "/" $ns) $p -}}
{{- end -}}
{{- else -}}
{{- $path -}}
{{- end -}}
{{- end -}}
{{- end -}}
