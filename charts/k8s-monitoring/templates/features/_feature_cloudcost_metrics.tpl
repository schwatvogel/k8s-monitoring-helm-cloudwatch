{{- define "features.cloudCostMetrics.enabled" }}{{ .Values.cloudCostMetrics.enabled }}{{- end }}

{{- define "features.cloudCostMetrics.include" }}
{{- if .Values.cloudCostMetrics.enabled -}}
{{- $destinations := include "features.cloudCostMetrics.destinations" . | fromYamlArray }}
// Feature: Cloud Cost Metrics
{{- include "feature.cloudCostMetrics.module" (dict "Values" $.Values.cloudCostMetrics "Files" $.Subcharts.cloudCostMetrics.Files "Release" $.Release) }}
cloudcost_metrics "feature" {
  metrics_destinations = [
    {{ include "dataProcessors.pipeline.targets.forFeature" (dict "root" $ "featureKey" "cloudCostMetrics" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") | indent 4 | trim }}
  ]
}
{{- include "dataProcessors.pipeline.render.forFeature" (dict "root" $ "featureKey" "cloudCostMetrics" "destinationNames" $destinations "type" "metrics" "ecosystem" "prometheus") }}
{{- end -}}
{{- end -}}

{{- define "features.cloudCostMetrics.destinations" }}
{{- if .Values.cloudCostMetrics.enabled -}}
{{- include "destinations.get" (dict "destinations" $.Values.destinations "type" "metrics" "ecosystem" "prometheus" "filter" $.Values.cloudCostMetrics.destinations) -}}
{{- end -}}
{{- end -}}

{{- define "features.cloudCostMetrics.destinations.isTranslating" }}
{{- $isTranslating := false -}}
{{- $destinations := include "features.cloudCostMetrics.destinations" . | fromYamlArray -}}
{{ range $destination := $destinations -}}
  {{- $destinationEcosystem := include "destination.getEcosystem" (deepCopy $ | merge (dict "destination" $destination)) -}}
  {{- if ne $destinationEcosystem "prometheus" -}}
    {{- $isTranslating = true -}}
  {{- end -}}
{{- end -}}
{{- $isTranslating -}}
{{- end -}}

{{- define "features.cloudCostMetrics.collector.values" }}{{- end -}}

{{/* Reports whether the collector runs more than one Alloy instance, and so could scrape the same Cloud Cost Exporter
     more than once. Mirrors the checks in collectors.validate.clusteringEnabled.
     Inputs: Values, Files, collectorName (string) */}}
{{- define "features.cloudCostMetrics.collectorRunsMultipleInstances" }}
{{- $collectorValues := include "collector.alloy.valuesWithUpstream" (dict "Values" .Values "Files" .Files "collectorName" .collectorName) | fromYaml }}
{{- $controllerType := dig "controller" "type" "daemonset" $collectorValues }}
{{- $replicas := dig "controller" "replicas" 1 $collectorValues }}
{{- $hpaEnabled := or (dig "controller" "autoscaling" "enabled" false $collectorValues) (dig "controller" "autoscaling" "horizontal" "enabled" false $collectorValues) }}
{{- or (eq $controllerType "daemonset") (gt (int $replicas) 1) $hpaEnabled }}
{{- end -}}

{{/* The generated prometheus.scrape components enable clustering, which shards the exporter targets across replicas.
     Without clustering, a multi-replica collector would scrape every exporter from every replica, producing
     duplicate samples. This is the same condition as collectors.validate.clusteringEnabled, reported separately so
     the remedy can lead with the singleton preset.
     Inputs: Values, Files, collectorName (string) */}}
{{- define "features.cloudCostMetrics.validate.scrapesAreNotDuplicated" }}
{{- if .collectorName }}
  {{- if eq (include "features.cloudCostMetrics.collectorRunsMultipleInstances" .) "true" }}
    {{- $collectorValues := include "collector.alloy.valuesWithUpstream" (dict "Values" .Values "Files" .Files "collectorName" .collectorName) | fromYaml }}
    {{- if not (dig "alloy" "clustering" "enabled" false $collectorValues) }}
      {{- $msg := list "" (printf "The Cloud Cost metrics feature is assigned to the %s collector, which runs more than one Alloy instance without clustering." .collectorName) }}
      {{- $msg = append $msg "Every instance would scrape the same Cloud Cost Exporter, producing duplicate samples." }}
      {{- $msg = append $msg "Please run the collector as a single instance:" }}
      {{- $msg = append $msg "collectors:" }}
      {{- $msg = append $msg (printf "  %s:" .collectorName) }}
      {{- $msg = append $msg "    presets: [singleton]" }}
      {{- $msg = append $msg "Or, to keep scaling out, enable clustering so the scrapes are shared between instances:" }}
      {{- $msg = append $msg (printf "  %s:" .collectorName) }}
      {{- $msg = append $msg "    presets: [clustered]" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{- define "features.cloudCostMetrics.validate" }}
{{- if .Values.cloudCostMetrics.enabled }}
  {{- $featureKey := "cloudCostMetrics" }}
  {{- $featureName := "Cloud Cost metrics" }}
  {{- $destinations := include "features.cloudCostMetrics.destinations" . | fromYamlArray }}
  {{- include "destinations.validate.destinationListNotEmpty" (dict "destinations" $destinations "type" "metrics" "ecosystem" "prometheus" "featureName" $featureName "Values" $.Values "featureKey" $featureKey) }}
  {{- include "dataProcessors.validate.feature" (dict "root" $ "featureKey" $featureKey "featureName" $featureName "type" "metrics" "ecosystem" "prometheus") }}

  {{- $collectorName := include "collectors.getCollectorForFeature" (dict "Values" $.Values "featureKey" $featureKey) }}
  {{- include "collectors.validate.collectorIsAssigned" (dict "Values" $.Values "collectorName" $collectorName "featureKey" $featureKey "featureName" $featureName) }}
  {{- include "features.cloudCostMetrics.validate.scrapesAreNotDuplicated" (dict "Values" $.Values "Files" $.Files "collectorName" $collectorName) }}

  {{- include "feature.cloudCostMetrics.validate" (dict "Values" $.Values.cloudCostMetrics) }}
{{- end }}
{{- end }}
