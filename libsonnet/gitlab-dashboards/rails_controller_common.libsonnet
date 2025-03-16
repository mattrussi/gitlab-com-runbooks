local elasticsearchLinks = import 'elasticlinkbuilder/elasticsearch_links.libsonnet';
local matching = import 'elasticlinkbuilder/matching.libsonnet';
local toolingLinks = import 'toolinglinks/toolinglinks.libsonnet';
local toolingLinkDefinition = (import 'toolinglinks/tooling_link_definition.libsonnet').toolingLinkDefinition();
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local panel = import 'grafana/time-series/panel.libsonnet';

local elasticsearchLogSearchDataLink(type) = {
  url: elasticsearchLinks.buildElasticDiscoverSearchQueryURL(
    'rails',
    [
      matching.matchFilter('json.type.keyword', type),
      matching.matchFilter('json.controller.keyword', '$controller'),
    ],
    ['json.action.keyword:${action:lucene}']
  ),
  title: 'ElasticSearch: Rails logs',
  targetBlank: true,
};

local elasticsearchExternalHTTPLink(type) = function(options)
  [
    local filters = [
      matching.matchFilter('json.type', type),
      matching.existsFilter('json.external_http_count'),
    ];
    toolingLinkDefinition({
      title: '📖 Kibana: External HTTP logs',
      url: elasticsearchLinks.buildElasticDiscoverSearchQueryURL('rails', filters),
    }),
  ];


{
  dashboard(type, defaultController, defaultAction, useTimeSeriesPlugin=true)::
    local webserviceType = if type == null then '$type' else type;
    local tags = if type == null then ['detail'] else ['type:%s' % type, 'detail'];

    local selector = {
      environment: '$environment',
      type: webserviceType,
      stage: '$stage',
      controller: '$controller',
      action: { re: '$action' },
    };

    local selectorString = selectors.serializeHash(selector);

    basic.dashboard(
      'Rails Controller',
      tags=tags,
      includeEnvironmentTemplate=true,
    )
    .addTemplate(if type == null then templates.webserviceType else templates.constant('type', type))
    .addTemplate(templates.stage)
    .addTemplate(templates.railsController(defaultController))
    .addTemplate(templates.railsControllerAction(defaultAction))
    .addPanels(
      layout.grid(
        if useTimeSeriesPlugin then
          [
            panel.timeSeries(
              title='Request Rate',
              query='sum by (controller, action) (avg_over_time(controller_action:gitlab_transaction_duration_seconds_count:rate1m{%s}[$__interval]))' % selectorString,
              legendFormat='{{ action }}',
              format='ops',
              yAxisLabel='Requests per Second',
            ).addDataLink(elasticsearchLogSearchDataLink(webserviceType)),
            panel.multiTimeSeries(
              title='Latency',
              queries=[
                {
                  query: 'avg by (controller, action) (avg_over_time(controller_action:gitlab_transaction_duration_seconds:p99{%s}[$__interval]))' % selectorString,
                  legendFormat: '{{ action }} - p99',
                },
                {
                  query: 'avg by (controller, action) (avg_over_time(controller_action:gitlab_transaction_duration_seconds:p95{%s}[$__interval]))' % selectorString,
                  legendFormat: '{{ action }} - p95',
                },
                {
                  query: |||
                    sum by (controller, action) (avg_over_time(controller_action:gitlab_transaction_duration_seconds_sum:rate1m{%(selector)s}[$__interval]))
                    /
                    sum by (controller, action) (avg_over_time(controller_action:gitlab_transaction_duration_seconds_count:rate1m{%(selector)s}[$__interval]))
                  ||| % { selector: selectorString },
                  legendFormat: '{{ action }} - mean',
                },
              ],
              format='short',
            ).addDataLink(elasticsearchLogSearchDataLink(webserviceType)),
          ]
        else
          [
            basic.timeseries(
              stableId='request-rate',
              title='Request Rate',
              query='sum by (controller, action) (avg_over_time(controller_action:gitlab_transaction_duration_seconds_count:rate1m{%s}[$__interval]))' % selectorString,
              legendFormat='{{ action }}',
              format='ops',
              yAxisLabel='Requests per Second',
              decimals=1,
            ).addDataLink(elasticsearchLogSearchDataLink(webserviceType)),
            basic.multiTimeseries(
              stableId='latency',
              title='Latency',
              queries=[
                {
                  query: 'avg by (controller, action) (avg_over_time(controller_action:gitlab_transaction_duration_seconds:p99{%s}[$__interval]))' % selectorString,
                  legendFormat: '{{ action }} - p99',
                },
                {
                  query: 'avg by (controller, action) (avg_over_time(controller_action:gitlab_transaction_duration_seconds:p95{%s}[$__interval]))' % selectorString,
                  legendFormat: '{{ action }} - p95',
                },
                {
                  query: |||
                    sum by (controller, action) (avg_over_time(controller_action:gitlab_transaction_duration_seconds_sum:rate1m{%(selector)s}[$__interval]))
                    /
                    sum by (controller, action) (avg_over_time(controller_action:gitlab_transaction_duration_seconds_count:rate1m{%(selector)s}[$__interval]))
                  ||| % { selector: selectorString },
                  legendFormat: '{{ action }} - mean',
                },
              ],
              format='s',
            ).addDataLink(elasticsearchLogSearchDataLink(webserviceType)),
          ],
      )
      +
      layout.rowGrid(
        'SQL',
        if useTimeSeriesPlugin then
          [
            panel.multiTimeSeries(
              title='Total SQL Queries Rate',
              format='ops',
              queries=[
                {
                  query: |||
                    sum by (action) (
                      rate(
                        gitlab_transaction_db_count_total{%(selector)s}[$__interval]
                      )
                    )
                  ||| % { selector: selectorString },
                  legendFormat: 'Total - {{ action }}',
                },
                {
                  query: |||
                    sum by (action) (
                      rate(
                        gitlab_transaction_db_primary_count_total{%(selector)s}[$__interval]
                      )
                    )
                  ||| % { selector: selectorString },
                  legendFormat: 'Primary - {{ action }}',
                },
                {
                  query: |||
                    sum by (action) (
                      rate(
                        gitlab_transaction_db_replica_count_total{%(selector)s}[$__interval]
                      )
                    )
                  ||| % { selector: selectorString },
                  legendFormat: 'Replica - {{ action }}',
                },
              ]
            ),
            panel.timeSeries(
              title='SQL Requests per Controller Request',
              query=|||
                sum by (action) (
                  rate(gitlab_sql_duration_seconds_count{%(selector)s}[$__interval])
                )
                /
                sum by (action) (
                  avg_over_time(
                    controller_action:gitlab_transaction_duration_seconds_count:rate1m{%(selector)s}[$__interval]
                  )
                )
              ||| % { selector: selectorString },
              legendFormat='{{ action }}',
            ),
            panel.timeSeries(
              title='SQL Latency per Controller Request',
              query=|||
                sum by (controller, action) (avg_over_time(controller_action:gitlab_sql_duration_seconds_sum:rate1m{%(selector)s}[$__interval]))
                /
                sum by (controller, action) (avg_over_time(controller_action:gitlab_transaction_duration_seconds_count:rate1m{%(selector)s}[$__interval]))
              ||| % { selector: selectorString },
              legendFormat='{{ action }}',
              format='short'
            ),
            panel.timeSeries(
              title='SQL Latency per SQL Request',
              query=|||
                sum by (action) (
                  rate(gitlab_sql_duration_seconds_sum{%(selector)s}[$__interval])
                )
                /
                sum by (action) (
                  rate(gitlab_sql_duration_seconds_count{%(selector)s}[$__interval])
                )
              ||| % { selector: selectorString },
              legendFormat='{{ action }}',
            ),
          ]
        else
          [
            basic.multiTimeseries(
              stableId='total-sql-queries-rate',
              title='Total SQL Queries Rate',
              format='ops',
              decimals=1,
              queries=[
                {
                  query: |||
                    sum by (action) (
                      rate(
                        gitlab_transaction_db_count_total{%(selector)s}[$__interval]
                      )
                    )
                  ||| % { selector: selectorString },
                  legendFormat: 'Total - {{ action }}',
                },
                {
                  query: |||
                    sum by (action) (
                      rate(
                        gitlab_transaction_db_primary_count_total{%(selector)s}[$__interval]
                      )
                    )
                  ||| % { selector: selectorString },
                  legendFormat: 'Primary - {{ action }}',
                },
                {
                  query: |||
                    sum by (action) (
                      rate(
                        gitlab_transaction_db_replica_count_total{%(selector)s}[$__interval]
                      )
                    )
                  ||| % { selector: selectorString },
                  legendFormat: 'Replica - {{ action }}',
                },
              ]
            ),
            basic.timeseries(
              stableId='sql-requests-per-controller-request',
              title='SQL Requests per Controller Request',
              query=|||
                sum by (action) (
                  rate(gitlab_sql_duration_seconds_count{%(selector)s}[$__interval])
                )
                /
                sum by (action) (
                  avg_over_time(
                    controller_action:gitlab_transaction_duration_seconds_count:rate1m{%(selector)s}[$__interval]
                  )
                )
              ||| % { selector: selectorString },
              legendFormat='{{ action }}',
              decimals=1,
            ),
            basic.timeseries(
              stableId='sql-latency-per-controller-request',
              title='SQL Latency per Controller Request',
              query=|||
                sum by (controller, action) (avg_over_time(controller_action:gitlab_sql_duration_seconds_sum:rate1m{%(selector)s}[$__interval]))
                /
                sum by (controller, action) (avg_over_time(controller_action:gitlab_transaction_duration_seconds_count:rate1m{%(selector)s}[$__interval]))
              ||| % { selector: selectorString },
              legendFormat='{{ action }}',
              format='s'
            ),
            basic.timeseries(
              stableId='sql-latency-per-sql-request',
              title='SQL Latency per SQL Request',
              query=|||
                sum by (action) (
                  rate(gitlab_sql_duration_seconds_sum{%(selector)s}[$__interval])
                )
                /
                sum by (action) (
                  rate(gitlab_sql_duration_seconds_count{%(selector)s}[$__interval])
                )
              ||| % { selector: selectorString },
              legendFormat='{{ action }}',
              format='s'
            ),
          ],
        startRow=201
      )
      +
      layout.rowGrid(
        'SQL Transaction',
        if useTimeSeriesPlugin then
          [
            panel.timeSeries(
              title='SQL Transactions per Controller Request',
              query=|||
                sum by (action) (
                  rate(gitlab_database_transaction_seconds_count{%(selector)s}[$__interval])
                )
              ||| % { selector: selectorString },
              legendFormat='{{ action }}',
            ),
            panel.timeSeries(
              title='Average Duration per SQL Transaction',
              query=|||
                sum(rate(gitlab_database_transaction_seconds_sum{%(selector)s}[$__interval])) by (action)
                /
                sum(rate(gitlab_database_transaction_seconds_count{%(selector)s}[$__interval])) by (action)
              ||| % { selector: selectorString },
              legendFormat='{{ action }}',
              format='short'
            ),
          ]
        else
          [
            basic.timeseries(
              stableId='sql-transaction-per-controller-request',
              title='SQL Transactions per Controller Request',
              query=|||
                sum by (action) (
                  rate(gitlab_database_transaction_seconds_count{%(selector)s}[$__interval])
                )
              ||| % { selector: selectorString },
              legendFormat='{{ action }}',
              decimals=1,
            ),
            basic.timeseries(
              stableId='avg-duration-per-sql-transaction',
              title='Average Duration per SQL Transaction',
              query=|||
                sum(rate(gitlab_database_transaction_seconds_sum{%(selector)s}[$__interval])) by (action)
                /
                sum(rate(gitlab_database_transaction_seconds_count{%(selector)s}[$__interval])) by (action)
              ||| % { selector: selectorString },
              legendFormat='{{ action }}',
              format='s'
            ),
          ],
        startRow=301
      )
      +
      layout.rowGrid('Cache', [
        if useTimeSeriesPlugin then
          panel.timeSeries(
            title='Cache Operations',
            query=|||
              sum by (action, operation) (
                rate(gitlab_cache_operations_total{%(selector)s}[$__interval])
              )
            ||| % { selector: selectorString },
            legendFormat='{{ action }} - {{ operation }}',
          )
        else
          basic.timeseries(
            stableId='cache-operations',
            title='Cache Operations',
            query=|||
              sum by (action, operation) (
                rate(gitlab_cache_operations_total{%(selector)s}[$__interval])
              )
            ||| % { selector: selectorString },
            legendFormat='{{ action }} - {{ operation }}',
            decimals=1,
          ),
      ], startRow=401)
      +
      layout.rowGrid('Elasticsearch', [
        if useTimeSeriesPlugin then
          panel.multiQuantileTimeSeries('Elasticsearch Time', selector, '{{ action }}', bucketMetric='http_elasticsearch_requests_duration_seconds_bucket', aggregators='controller, ')
        else
          basic.multiQuantileTimeseries('Elasticsearch Time', selector, '{{ action }}', bucketMetric='http_elasticsearch_requests_duration_seconds_bucket', aggregators='controller, action'),
      ], startRow=501)
      +
      layout.rowGrid(
        'External HTTP',
        if useTimeSeriesPlugin then
          [
            panel.timeSeries(
              title='External HTTP calls',
              query=|||
                sum by (controller, action, code) (
                rate(gitlab_external_http_total{%(selector)s}[$__interval])
                )
              ||| % { selector: selectorString },
              legendFormat='{{ action }} - {{ code }}',
              format='ops',
            ),
            panel.multiTimeSeries(
              title='External HTTP Latency per call',
              queries=[{
                query: |||
                  histogram_quantile(
                    0.5,
                    sum(
                      rate(
                        gitlab_external_http_duration_seconds_bucket{%s}[5m]
                      )
                    ) by (action, le)
                  )
                ||| % selectorString,
                legendFormat: '{{ action }} - p50',
              }, {
                query: |||
                  histogram_quantile(
                    0.9,
                    sum(
                      rate(
                        gitlab_external_http_duration_seconds_bucket{%s}[5m]
                      )
                    ) by (action, le)
                  )
                ||| % selectorString,
                legendFormat: '{{ action }} - p90',
              }, {
                query: |||
                  histogram_quantile(
                    0.99,
                    sum(
                      rate(
                        gitlab_external_http_duration_seconds_bucket{%s}[5m]
                      )
                    ) by (action, le)
                  )
                ||| % selectorString,
                legendFormat: '{{ action }} - p99',
              }],
              format='short',
            ),
            grafana.text.new(
              title='Extra links',
              mode='markdown',
              content=|||
                The metrics displayed in this row indicate all the network requests made inside a Rails process via the HTTP protocol. The requests may be triggered by Gitlab::HTTP utility inside the application code base or by any 3rd-party gems. We don't differentiate the destinations. So, the metrics include both internal/external dependencies.
              ||| + toolingLinks.generateMarkdown([
                elasticsearchExternalHTTPLink(webserviceType),
              ])
            ),
          ]
        else
          [
            basic.timeseries(
              stableId='external-http',
              title='External HTTP calls',
              query=|||
                sum by (controller, action, code) (
                rate(gitlab_external_http_total{%(selector)s}[$__interval])
                )
              ||| % { selector: selectorString },
              legendFormat='{{ action }} - {{ code }}',
              format='ops',
              decimals=1,
            ),
            basic.multiTimeseries(
              stableId='external-http-latency',
              title='External HTTP Latency per call',
              queries=[{
                query: |||
                  histogram_quantile(
                    0.5,
                    sum(
                      rate(
                        gitlab_external_http_duration_seconds_bucket{%s}[5m]
                      )
                    ) by (action, le)
                  )
                ||| % selectorString,
                legendFormat: '{{ action }} - p50',
              }, {
                query: |||
                  histogram_quantile(
                    0.9,
                    sum(
                      rate(
                        gitlab_external_http_duration_seconds_bucket{%s}[5m]
                      )
                    ) by (action, le)
                  )
                ||| % selectorString,
                legendFormat: '{{ action }} - p90',
              }, {
                query: |||
                  histogram_quantile(
                    0.99,
                    sum(
                      rate(
                        gitlab_external_http_duration_seconds_bucket{%s}[5m]
                      )
                    ) by (action, le)
                  )
                ||| % selectorString,
                legendFormat: '{{ action }} - p99',
              }],
              format='s',
            ),
            grafana.text.new(
              title='Extra links',
              mode='markdown',
              content=|||
                The metrics displayed in this row indicate all the network requests made inside a Rails process via the HTTP protocol. The requests may be triggered by Gitlab::HTTP utility inside the application code base or by any 3rd-party gems. We don't differentiate the destinations. So, the metrics include both internal/external dependencies.
              ||| + toolingLinks.generateMarkdown([
                elasticsearchExternalHTTPLink(webserviceType),
              ])
            ),
          ],
        startRow=601
      )
      +
      layout.grid([])
    )
    .trailer(),
}
