local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local customRateQuery = metricsCatalog.customRateQuery;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'logging',
  tier: 'inf',
  /*
   * Until this service starts getting more predictable traffic volumes
   * disable anomaly detection for RPS
   */
  disableOpsRatePrediction: true,
  provisioning: {
    /* Provisioned with Elastic Cloud, no VMs, no Kube */
    vms: false,
    kubernetes: false,
  },
  serviceLevelIndicators: {

    elasticsearch_searching: {
      userImpacting: false,  // Consider updating once more widely rolled out
      description: |||
        Opensearch global search average rate.
      |||,

      requestRate: customRateQuery(|||
        label_replace(avg_over_time(aws_es_5xx_average[5m]), "status", "5xx","","")/60 or
        label_replace(avg_over_time(aws_es_4xx_average[5m]), "status", "4xx","","")/60 or
        label_replace(avg_over_time(aws_es_3xx_average[5m]), "status", "3xx","","")/60 or
        label_replace(avg_over_time(aws_es_2xx_average[5m]), "status", "2xx","","")/60
      |||),

      errorRate: customRateQuery(|||
        label_replace(avg_over_time(aws_es_5xx_average[5m]), "status", "5xx","","")/60
      |||),

      significantLabels: ['domain_name'],
    },

    firehose_record_delivery: {
      userImpacting: false,
      featureCategory: 'not_owned',
      description: |||
        This SLI monitors records delivered to Opensearch using Kinesis Firehose.
      |||,

      requestRate: customRateQuery(|||
        avg_over_time(aws_firehose_delivery_to_elasticsearch_records_average[%(burnRate)s])
      |||),

      significantLabels: ['name'],

    },
  },
})
