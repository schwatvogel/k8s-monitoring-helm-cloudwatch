{{- /*
Validates the Cloud Cost Exporter instances defined on the feature. Every instance needs a name, which becomes the
metrics' instance label and the Alloy component label. Because the name is normalized into an Alloy component label,
two instances that differ only in punctuation would generate colliding components, so compare the normalized names.
Inputs: .Values (the cloudCostMetrics feature values)
*/ -}}
{{- define "feature.cloudCostMetrics.validate" }}
{{- $names := list }}
{{- range $index, $instance := .Values.instances }}
  {{- if not $instance.name }}
    {{- $msg := list "" (printf "The cloudCostMetrics instance at position %d has no name." (add $index 1)) }}
    {{- $msg = append $msg "Every instance needs a name, which is used as the metrics' instance label:" }}
    {{- $msg = append $msg "cloudCostMetrics:" }}
    {{- $msg = append $msg "  instances:" }}
    {{- $msg = append $msg "    - name: my-aws-account" }}
    {{- fail (join "\n" $msg) }}
  {{- end }}

  {{- $alloyName := include "helper.alloy_name" $instance.name }}
  {{- if has $alloyName $names }}
    {{- $msg := list "" (printf "More than one cloudCostMetrics instance resolves to the name %q." $alloyName) }}
    {{- $msg = append $msg "Instance names must be unique, and are compared with \"-\", \" \", and \"_\" treated as equal." }}
    {{- fail (join "\n" $msg) }}
  {{- end }}
  {{- $names = append $names $alloyName }}

  {{- /* An instance with an explicit address must still provide a usable host:port. The service path always resolves
         to a default, so only the explicitly-set address is checked here. */ -}}
  {{- if and (hasKey $instance "address") $instance.address }}
    {{- if not (regexMatch "^[^:]+:[0-9]+$" $instance.address) }}
      {{- $msg := list "" (printf "The cloudCostMetrics instance %q has an address %q that is not in host:port form." $instance.name $instance.address) }}
      {{- $msg = append $msg "Set the address as host and port, for example:" }}
      {{- $msg = append $msg "cloudCostMetrics:" }}
      {{- $msg = append $msg "  instances:" }}
      {{- $msg = append $msg (printf "    - name: %s" $instance.name) }}
      {{- $msg = append $msg "      address: cloudcost-exporter.monitoring.svc:8080" }}
      {{- fail (join "\n" $msg) }}
    {{- end }}
  {{- end }}
{{- end }}
{{- end }}
