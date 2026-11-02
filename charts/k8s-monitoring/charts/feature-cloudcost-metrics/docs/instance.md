# Cloud Cost Exporter Instance Settings

These are the settings available on each entry in `cloudCostMetrics.instances`. Every instance becomes its own
`prometheus.scrape` and `prometheus.relabel`, scraping one
[Cloud Cost Exporter](https://github.com/grafana/cloudcost-exporter) and forwarding its metrics to the feature's
destinations.

## Target

By default an instance scrapes the in-cluster Cloud Cost Exporter Service deployed by
`telemetryServices.cloudcost-exporter`, which resolves to `<release>-cloudcost-exporter` in the release namespace.

To scrape a different Service — for example one deployed under another name or namespace — set the `service` fields.
To scrape a Cloud Cost Exporter this chart does not deploy at all, set `address` to its `host:port`, which takes
precedence over `service`:

```yaml
instances:
  - name: external
    address: cloudcost-exporter.monitoring.svc:8080
```

## Multiple accounts

The Cloud Cost Exporter assumes a single role per process, so to gather costs from several AWS accounts, deploy one
exporter per account (each with its own `--aws.roleARN`) and add one instance per exporter:

```yaml
instances:
  - name: account-a
    address: cloudcost-a.monitoring.svc:8080
  - name: account-b
    address: cloudcost-b.monitoring.svc:8080
```

## Metric processing

`metrics.tuning.includeMetrics` and `metrics.tuning.excludeMetrics` filter which series are kept, and
`metrics.extraMetricProcessingRules` adds raw `prometheus.relabel` rule blocks. `labels` adds static labels to every
metric from the instance.

## Values

### Target

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| address | string | `""` | Explicit scrape target address (`host:port`) for a Cloud Cost Exporter that this chart does not deploy, such as one managed outside the chart. When set, it takes precedence over `service`. Leave empty to target a Cloud Cost Exporter deployed by `telemetryServices.cloudcost-exporter`. |
| service.metricsPath | string | `"/metrics"` | The HTTP path to scrape metrics from. |
| service.name | string | `<release>-cloudcost-exporter` | Name of the Cloud Cost Exporter Service to scrape. |
| service.namespace | string | Release namespace | Namespace of the Cloud Cost Exporter Service. Defaults to the release namespace. |
| service.port | int | `8080` | Port of the Cloud Cost Exporter Service. |

### General Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| jobLabel | string | `"integrations/cloudcost-exporter"` | The value of the job label for metrics scraped from this instance. |
| labels | object | `{}` | Extra labels to add to all metrics scraped from this instance. Format: `<label>: <value>`. |
| name | string | `""` | Name for this Cloud Cost Exporter instance. Used as the `instance` label on the scraped metrics and to name the generated Alloy components, so it must be unique within the feature. |

### Metric Processing Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.extraMetricProcessingRules | string | `""` | Rule blocks to be added to the prometheus.relabel component for this instance. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#rule-block)) These relabeling rules are applied post-scrape against the metrics returned from the scraped target. |
| metrics.maxCacheSize | int | `100000` | Sets the max_cache_size for the prometheus.relabel component for this instance. This should be at least 2x-5x your largest scrape target or samples appended rate. ([docs](https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.relabel/#arguments)). Overrides `global.maxCacheSize`. |
| metrics.tuning.excludeMetrics | list | `[]` | Metrics to drop. Can use regular expressions. |
| metrics.tuning.includeMetrics | list | `[]` | Metrics to keep. Can use regular expressions. |

### Scrape Settings

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metrics.scrapeInterval | string | `60s` | How frequently to scrape metrics from the Cloud Cost Exporter. Overrides `global.scrapeInterval`. |
| metrics.scrapeTimeout | string | `10s` | The timeout for scraping metrics from the Cloud Cost Exporter. Overrides `global.scrapeTimeout`. |
