<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify README.md.gotmpl and run `helm-docs`)
-->

# Feature: Cloud Cost Metrics

The Cloud Cost Metrics feature scrapes cost rate metrics from one or more
[Cloud Cost Exporter](https://github.com/grafana/cloudcost-exporter) instances and delivers them to your metrics
destinations alongside the rest of your Kubernetes telemetry.

## Usage

```yaml
cloudCostMetrics:
  enabled: true
  instances:
    - name: production
```

With no further settings, an instance scrapes the Cloud Cost Exporter deployed by
`telemetryServices.cloudcost-exporter`. Each entry in `instances` becomes its own scrape, so use separate instances to
gather from several exporters — for example one exporter per AWS account, since the exporter assumes a single role per
process. See the [instance settings](./docs/instance.md) for everything available on an entry.

## How it works

For every instance, this feature generates a `prometheus.scrape` that gathers from the Cloud Cost Exporter, and a
`prometheus.relabel` that sets the `instance` and `job` labels and applies any metric tuning.

By default the scrape targets the in-cluster Cloud Cost Exporter Service. To scrape an exporter this chart does not
deploy, set `address` on the instance.

### Deploying the exporter

The Cloud Cost Exporter workload is deployed by the telemetry service, not this feature:

```yaml
telemetryServices:
  cloudcost-exporter:
    deploy: true
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/CloudCostExporterRole
```

The exporter authenticates with AWS using the credentials available to its Pod, which is the normal setup with
[IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) or
[EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html). To gather costs from another
AWS account, add `--aws.roleARN=<role-arn>` to its `containerArgs` and deploy one exporter per account.

## Testing

This chart contains unit tests to verify the generated configuration. The hidden value `testing.enabled` will render
the generated configuration into a ConfigMap object. While this ConfigMap is not used during regular operation, you can
use it to show the outcome of a given values file.

The unit tests use this ConfigMap to create an object with the configuration that can be asserted against. To run the
tests, use `helm test`.

Be sure perform actual integration testing in a live environment in the main [k8s-monitoring](../..) chart.

<!-- textlint-disable terminology -->
## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| schwatvogel | <572536+schwatvogel@users.noreply.github.com> |  |
<!-- textlint-enable terminology -->
<!-- markdownlint-disable no-bare-urls -->
<!-- markdownlint-disable list-marker-space -->
## Source Code

* <https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-cloudcost-metrics>
<!-- markdownlint-enable list-marker-space -->
<!-- markdownlint-enable no-bare-urls -->

## Values

### Global Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| global.maxCacheSize | int | `100000` | Sets the max_cache_size for every prometheus.relabel component. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)) This should be at least 2x-5x your largest scrape target or samples appended rate. |
| global.namespaceOverride | string | `""` | Override the namespace for namespaced resources created by this chart. |
| global.scrapeClassicHistograms | bool | `false` | Whether to scrape a classic histogram that’s also exposed as a native histogram. |
| global.scrapeInterval | string | `"60s"` | How frequently to scrape metrics. |
| global.scrapeNativeHistograms | bool | `false` | Whether to scrape native histograms. |
| global.scrapeProtocols | list | `["OpenMetricsText1.0.0","OpenMetricsText0.0.1","PrometheusText0.0.4"]` | The protocols to negotiate during a Prometheus metrics scrape, in order of preference. |
| global.scrapeTimeout | string | `"10s"` | The timeout for scraping metrics. |

### Instances

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| instances | list | `[]` | One entry per Cloud Cost Exporter to scrape. Each instance becomes its own `prometheus.scrape` and `prometheus.relabel`, so use separate instances to gather from several exporters — for example one exporter per AWS account, since the exporter assumes a single role per process. See the [instance settings](./docs/instance.md) for the options available on each entry. |

### Instance Settings

These are the settings for each entry in `instances`. See the [instance settings](./docs/instance.md) for the target,
scrape, and metric processing options on each entry.

#### Target

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| address | string | `""` | Explicit scrape target address (`host:port`) for a Cloud Cost Exporter that this chart does not deploy, such as one managed outside the chart. When set, it takes precedence over `service`. Leave empty to target a Cloud Cost Exporter deployed by `telemetryServices.cloudcost-exporter`. |
| service.metricsPath | string | `"/metrics"` | The HTTP path to scrape metrics from. |
| service.name | string | `<release>-cloudcost-exporter` | Name of the Cloud Cost Exporter Service to scrape. |
| service.namespace | string | Release namespace | Namespace of the Cloud Cost Exporter Service. Defaults to the release namespace. |
| service.port | int | `8080` | Port of the Cloud Cost Exporter Service. |

#### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| jobLabel | string | `"integrations/cloudcost-exporter"` | The value of the job label for metrics scraped from this instance. |
| labels | object | `{}` | Extra labels to add to all metrics scraped from this instance. Format: `<label>: <value>`. |
| name | string | `""` | Name for this Cloud Cost Exporter instance. Used as the `instance` label on the scraped metrics and to name the generated Alloy components, so it must be unique within the feature. |

#### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for this instance. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) These relabeling rules are applied post-scrape against the metrics returned from the scraped target. |
| metrics.maxCacheSize | int | `100000` | Sets the max_cache_size for the prometheus.relabel component for this instance. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)). Overrides `global.maxCacheSize`. |
| metrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

#### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from the Cloud Cost Exporter. Overrides `global.scrapeInterval`. |
| metrics.scrapeTimeout | string | `10s` | The timeout for scraping metrics from the Cloud Cost Exporter. Overrides `global.scrapeTimeout`. |
