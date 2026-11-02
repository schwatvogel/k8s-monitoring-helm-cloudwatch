{{- define "feature.cloudCostMetrics.notes.deployments" }}{{- end }}

{{- define "feature.cloudCostMetrics.notes.task" }}
Scrape cloud cost rate metrics from {{ len .Values.instances }} Cloud Cost Exporter instance{{ if ne (len .Values.instances) 1 }}s{{ end }}
{{- end }}

{{- /* NOTES.txt calls notes.actions with the root context, so the feature's own values are reached through
       .Values.cloudCostMetrics rather than .Values. */ -}}
{{- define "feature.cloudCostMetrics.notes.actions" }}
{{- $deployed := dig "cloudcost-exporter" "deploy" false (.Values.telemetryServices | default dict) }}
{{- if not $deployed }}
* No Cloud Cost Exporter is being deployed by this chart. Make sure each cloudCostMetrics instance either points at an
  existing exporter with `address`, or enable one with `telemetryServices.cloudcost-exporter.deploy: true`.
{{- end }}
{{- end }}

{{- define "feature.cloudCostMetrics.summary" -}}
version: {{ .Chart.Version }}
{{- end }}
