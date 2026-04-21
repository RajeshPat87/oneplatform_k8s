{{- define "calculator-frontend.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- define "calculator-frontend.fullname" -}}
{{- printf "%s" (include "calculator-frontend.name" .) -}}
{{- end -}}
{{- define "calculator-frontend.labels" -}}
app.kubernetes.io/name: {{ include "calculator-frontend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: oneplatform
{{- end -}}
{{- define "calculator-frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "calculator-frontend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
