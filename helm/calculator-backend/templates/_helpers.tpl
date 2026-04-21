{{- define "calculator-backend.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "calculator-backend.fullname" -}}
{{- printf "%s" (include "calculator-backend.name" .) -}}
{{- end -}}

{{- define "calculator-backend.labels" -}}
app.kubernetes.io/name: {{ include "calculator-backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: oneplatform
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}

{{- define "calculator-backend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "calculator-backend.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
