<!--
(NOTE: Do not edit README.md directly. It is a generated file!)
(      To make changes, please modify values.yaml or description.txt and run `make examples`)
-->
# Cloud Cost Metrics from several AWS accounts

This example gathers cloud cost rate metrics from more than one AWS account using the
[Cloud Cost Exporter](https://github.com/grafana/cloudcost-exporter).

The Cloud Cost Exporter assumes a single role per process, so each AWS account needs its own exporter. The chart
deploys one exporter for the cluster's own account via `telemetryServices.cloudcost-exporter`, authenticated with IRSA.
A second exporter for another account is deployed separately, and the feature scrapes it by setting an explicit
`address` on a second instance.

Each instance becomes its own scrape with a distinct `instance` label, and the `audit-account` instance adds a static
`account` label so its series can be told apart downstream.

## Values

<!-- textlint-disable terminology -->
```yaml
---
cluster:
  name: cloudcost-metrics-cluster

destinations:
  prometheus:
    type: prometheus
    url: http://prometheus.prometheus.svc:9090/api/v1/write

# Deploy a Cloud Cost Exporter for the cluster's own AWS account, authenticated via IRSA.
telemetryServices:
  cloudcost-exporter:
    deploy: true
    containerArgs:
      - --provider=aws
      - --aws.region=us-east-1
      - --aws.services=EC2,S3,RDS,ELB,NATGATEWAY,VPC
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::111111111111:role/CloudCostExporterRole

cloudCostMetrics:
  enabled: true
  collector: alloy-metrics
  instances:
    # Scrapes the Cloud Cost Exporter deployed above for this cluster's AWS account.
    - name: local-account

    # Scrapes a second Cloud Cost Exporter, deployed separately for another AWS account (the exporter assumes a single
    # role per process, so each account needs its own exporter). Point at it with an explicit address.
    - name: audit-account
      address: cloudcost-exporter-audit.monitoring.svc:8080
      labels:
        account: audit

collectors:
  alloy-metrics:
    presets: [clustered]
```
<!-- textlint-enable terminology -->
