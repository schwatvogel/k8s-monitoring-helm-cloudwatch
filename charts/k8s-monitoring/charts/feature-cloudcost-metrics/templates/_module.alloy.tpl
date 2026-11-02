{{- /*
Resolves the scrape target address for an instance. An explicit `address` wins; otherwise the in-cluster Cloud Cost
Exporter Service is used, defaulting to the one deployed by telemetryServices.cloudcost-exporter
(`<release>-cloudcost-exporter`) in the release namespace.
Inputs: . (root context), instance (merged with defaults)
*/ -}}
{{- define "feature.cloudCostMetrics.instance.address" }}
{{- $instance := .instance }}
{{- if $instance.address }}
{{- $instance.address }}
{{- else }}
{{- $serviceName := $instance.service.name | default (printf "%s-cloudcost-exporter" .Release.Name) }}
{{- $serviceNamespace := $instance.service.namespace | default (include "helper.namespace" .) }}
{{- printf "%s.%s.svc:%v" $serviceName $serviceNamespace $instance.service.port }}
{{- end }}
{{- end }}

{{- /*
Renders one Cloud Cost Exporter instance: a prometheus.scrape targeting the exporter and a prometheus.relabel that
sets the instance and job labels, applies any extra labels and metric tuning, and forwards to the metrics
destinations.
Inputs: . (root context), instance (this Cloud Cost instance)
*/ -}}
{{- define "feature.cloudCostMetrics.instance" }}
{{- $defaults := "instance-defaults.yaml" | .Files.Get | fromYaml }}
{{- $root := . }}
{{- with mergeOverwrite $defaults .instance }}
{{- $alloyName := include "helper.alloy_name" .name }}
{{- $address := include "feature.cloudCostMetrics.instance.address" (dict "instance" . "Release" $root.Release "Values" $root.Values) }}
prometheus.scrape {{ $alloyName | quote }} {
  targets = [{
    __address__ = {{ $address | quote }},
    __metrics_path__ = {{ .service.metricsPath | quote }},
  }]
  job_name = {{ .jobLabel | quote }}
  clustering {
    enabled = true
  }

  scrape_interval = {{ .metrics.scrapeInterval | default $root.Values.global.scrapeInterval | quote }}
  scrape_timeout = {{ .metrics.scrapeTimeout | default $root.Values.global.scrapeTimeout | quote }}
  scrape_protocols = {{ include "helper.scrapeProtocols" $root }}
  scrape_classic_histograms = {{ $root.Values.global.scrapeClassicHistograms }}
  scrape_native_histograms = {{ $root.Values.global.scrapeNativeHistograms }}
  forward_to = [prometheus.relabel.{{ $alloyName }}.receiver]
} // prometheus.scrape {{ $alloyName | quote }}

prometheus.relabel {{ $alloyName | quote }} {
  max_cache_size = {{ .metrics.maxCacheSize | default $root.Values.global.maxCacheSize | int }}
  rule {
    target_label = "instance"
    replacement = {{ .name | quote }}
  }
  rule {
    target_label = "job"
    replacement = {{ .jobLabel | quote }}
  }
  {{- range $label, $value := .labels }}
  rule {
    target_label = {{ $label | quote }}
    replacement = {{ $value | quote }}
  }
  {{- end }}
  {{- if .metrics.tuning.includeMetrics }}
  rule {
    source_labels = ["__name__"]
    regex = "up|scrape_samples_scraped|{{ .metrics.tuning.includeMetrics | join "|" }}"
    action = "keep"
  }
  {{- end }}
  {{- if .metrics.tuning.excludeMetrics }}
  rule {
    source_labels = ["__name__"]
    regex = {{ .metrics.tuning.excludeMetrics | join "|" | quote }}
    action = "drop"
  }
  {{- end }}
  {{- with .metrics.extraMetricProcessingRules }}
  {{ . | indent 2 | trim }}
  {{- end }}
  forward_to = argument.metrics_destinations.value
} // prometheus.relabel {{ $alloyName | quote }}
{{- end }}
{{- end }}

{{- define "feature.cloudCostMetrics.module" }}
declare "cloudcost_metrics" {
  argument "metrics_destinations" {
    comment = "Must be a list of metric destinations where collected metrics should be forwarded to"
  }
{{- range $instance := .Values.instances }}
  {{- print "\n" }}
  {{- include "feature.cloudCostMetrics.instance" (deepCopy $ | merge (dict "instance" $instance)) | trim | nindent 2 }}
{{- end }}
} // declare "cloudcost_metrics"
{{- end -}}
