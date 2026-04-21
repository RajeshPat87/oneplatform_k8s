{{- define "calculator-ai-service.name" -}}{{- .Chart.Name -}}{{- end -}}
{{- define "calculator-ai-service.fullname" -}}{{- .Chart.Name -}}{{- end -}}
{{- define "calculator-ai-service.labels" -}}
app.kubernetes.io/name: {{ include "calculator-ai-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: oneplatform
{{- end -}}
{{- define "calculator-ai-service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "calculator-ai-service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
