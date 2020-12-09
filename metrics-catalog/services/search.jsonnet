local metricsCatalog = import 'servicemetrics/metrics.libsonnet';
local histogramApdex = metricsCatalog.histogramApdex;
local rateMetric = metricsCatalog.rateMetric;
local derivMetric = metricsCatalog.derivMetric;
local customQuery = metricsCatalog.customQuery;

metricsCatalog.serviceDefinition({
  type: 'search',
  tier: 'inf',
  /*
   * Until this service starts getting more predictable traffic volumes
   * disable anomaly detection for RPS
   */
  disableOpsRatePrediction: true,
  serviceLevelIndicators: {

    elasticsearch_searching: {
      userImpacting: false,  // Consider updating once more widely rolled out
      featureCategory: 'global_search',
      description: |||
        Aggregation of all search queries on GitLab.com, as measured from ElasticSearch.
      |||,

      requestRate: derivMetric(
        counter='elasticsearch_indices_search_query_total',
        selector='type="search"',
        clampMinZero=true,
      ),

      significantLabels: ['name'],
    },

    elasticsearch_indexing: {
      userImpacting: false,  // Consider updating once more widely rolled out
      featureCategory: 'global_search',
      description: |||
        Aggregation of all document indexing requests on GitLab.com, as measured from ElasticSearch.
      |||,

      requestRate: derivMetric(
        counter='elasticsearch_indices_indexing_index_total',
        selector='type="search"',
        clampMinZero=true,
      ),

      significantLabels: ['name'],
    },
  },
})
