{{- define "grafascope.common.victoriaService" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "victoria.fullname" . }}
  labels:
    {{- include "victoria.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  selector:
    {{- include "victoria.selectorLabels" . | nindent 4 }}
  ports:
    - name: http
      {{- $port := include (printf "%s.globalPort" .Chart.Name) . }}
      port: {{ default .Values.service.port $port }}
      targetPort: http
{{- end }}

{{- define "grafascope.common.victoriaIngress" -}}
{{- $path := include (printf "%s.globalPath" .Chart.Name) . -}}
{{- $port := include (printf "%s.globalPort" .Chart.Name) . -}}
{{- include "grafascope.common.ingress" (dict
  "context" .
  "name" (include "victoria.fullname" .)
  "labels" (include "victoria.labels" .)
  "serviceName" (include "victoria.fullname" .)
  "servicePort" (default .Values.service.port $port)
  "path" $path
  "pathType" "Prefix"
  "ingress" .Values.ingress
  "rewrite" (dict "enabled" false "target" "")
) }}
{{- end }}

{{- define "grafascope.common.victoriaStatefulSet" -}}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "victoria.fullname" . }}
  labels:
    {{- include "victoria.labels" . | nindent 4 }}
spec:
  serviceName: {{ include "victoria.fullname" . }}
  replicas: 1
  selector:
    matchLabels:
      {{- include "victoria.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "victoria.selectorLabels" . | nindent 8 }}
      annotations:
        {{- toYaml .Values.podAnnotations | nindent 8 }}
    spec:
      {{- with .Values.nodeSelector }}
      nodeSelector:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          {{- $args := .Values.args }}
          {{- $pathPrefix := .Values.httpPathPrefix }}
          {{- if not $pathPrefix }}
          {{- $globalPath := include (printf "%s.globalPath" .Chart.Name) . }}
          {{- if $globalPath }}
          {{- $pathPrefix = $globalPath }}
          {{- end }}
          {{- end }}
          args:
            {{- range $args }}
            - {{ . | quote }}
            {{- end }}
            {{- if $pathPrefix }}
            - {{ printf "-http.pathPrefix=%s" $pathPrefix | quote }}
            {{- end }}
          ports:
            - name: http
              {{- $port := include (printf "%s.globalPort" .Chart.Name) . }}
              containerPort: {{ default .Values.service.port $port }}
          volumeMounts:
            {{- if .Values.persistence.enabled }}
            - name: data
              mountPath: {{ .Values.persistence.mountPath }}
            {{- end }}
          {{- $healthPath := .Values.healthPath }}
          {{- if not $healthPath }}
          {{- $globalPath := include (printf "%s.globalPath" .Chart.Name) . }}
          {{- if $globalPath }}
          {{- $healthPath = printf "%s/health" $globalPath }}
          {{- end }}
          {{- end }}
          {{- if not $healthPath }}
          {{- $healthPath = "/health" }}
          {{- end }}
          readinessProbe:
            httpGet:
              path: {{ $healthPath | quote }}
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: {{ $healthPath | quote }}
              port: http
            initialDelaySeconds: 20
            periodSeconds: 20
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
      {{- if and .Values.persistence.enabled .Values.persistence.existingClaim }}
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: {{ .Values.persistence.existingClaim }}
      {{- end }}
  {{- if and .Values.persistence.enabled (not .Values.persistence.existingClaim) }}
  volumeClaimTemplates:
    - metadata:
        name: data
        labels:
          {{- include "victoria.labels" . | nindent 10 }}
      spec:
        accessModes:
          {{- toYaml .Values.persistence.accessModes | nindent 10 }}
        resources:
          requests:
            storage: {{ .Values.persistence.size | quote }}
        {{- if .Values.persistence.storageClass }}
        storageClassName: {{ .Values.persistence.storageClass | quote }}
        {{- end }}
  {{- end }}
{{- end }}

