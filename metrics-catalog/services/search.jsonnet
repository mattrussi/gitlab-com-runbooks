local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local derivMetric = metricsCatalog.derivMetric;
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';

metricsCatalog.serviceDefinition({
  type: 'search',
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
      featureCategory: 'global_search',
      description: |||
        Aggregation of all search queries on GitLab.com, as measured from ElasticSearch.
      |||,

      requestRate: derivMetric(
        counter='elasticsearch_indices_search_query_total',
        selector={ type: 'search' },
        clampMinZero=true,
      ),

      significantLabels: ['name'],

      toolingLinks: [
        toolingLinks.kibana(title='Elasticsearch', index='search', includeMatchersForPrometheusSelector=false),
      ],
    },

    elasticsearch_indexing: {
      userImpacting: false,  // Consider updating once more widely rolled out
      featureCategory: 'global_search',
      description: |||
        Aggregation of all document indexing requests on GitLab.com, as measured from ElasticSearch.
      |||,

      requestRate: derivMetric(
        counter='elasticsearch_indices_indexing_index_total',
        selector={ type: 'search' },
        clampMinZero=true,
      ),

      significantLabels: ['name'],

      toolingLinks: [
        toolingLinks.kibana(title='Elasticsearch', index='search', includeMatchersForPrometheusSelector=false),
      ],
    },
  },
})
