local elasticsearchLinks = import 'elasticlinkbuilder/elasticsearch_links.libsonnet';
local matching = import 'elasticlinkbuilder/matching.libsonnet';

local conditionScript = |||
  ctx.payload.aggregations.key.buckets.length > 0
|||;

local percentileThresholdTransformerScript(percentileFormatted, displayUnitDivisionFactor) =
  |||
    String extractFeatureCategory(def bucket) {
      def feature_category = bucket.feature_category_top_hit;
      if (feature_category == null) { return ""; }

      def hits = feature_category.hits.hits;
      if (hits.length == 0) { return ""; }

      def topHit = hits[0];
      def source = topHit._source;
      if (source ==  null) { return ""; }

      def json = source.json;
      if (json ==  null) { return ""; }

      def fc = json['meta.feature_category'];
      if (fc == null) { return ""; }

      return fc;
    }

    def items = ctx.payload.aggregations.key.buckets
      .collect(bucket -> {
        def v = bucket.agg_value.values['%(percentileFormatted)s'];
        def maxValue = bucket.max_value.value;

        [
        'key': bucket.key,
        'value': v,
        'percentileFormattedValue': new DecimalFormat("###,###.###").format(v / %(displayUnitDivisionFactor)g),
        'maxValueFormatted': new DecimalFormat("###,###.###").format(maxValue / %(displayUnitDivisionFactor)g),
        'feature_category': extractFeatureCategory(bucket),
        'doc_count': bucket.doc_count
        ]
      });

    items.sort((a,b) -> Double.compare(b.value, a.value));

    [
        'items': items.subList(0, items.length > params.maxElementsReturned ? params.maxElementsReturned : items.length)
    ];
  ||| % {
    percentileFormatted: percentileFormatted,
    displayUnitDivisionFactor: displayUnitDivisionFactor,
  };

local painlessScript(script, params={}) = {
  script: {
    inline: script,
    lang: 'painless',
    params: params,
  },
};

local searchLinkTemplate(elasticsearchIndexName, keyField, percentileValueField, thresholdValue, scheduleHours) =
  local timeRange = elasticsearchLinks.getCustomTimeRange('now-' + scheduleHours + 'h', 'now');
  elasticsearchLinks.buildElasticDiscoverSearchQueryURL(
    elasticsearchIndexName,
    filters=[
      matching.matchFilter(keyField, '{{#url}}{{key}}{{/url}}'),
      matching.rangeFilter(percentileValueField, lteValue=null, gteValue=thresholdValue),
    ],
    timeRange=timeRange,
    sort=[[percentileValueField, 'desc']],
    extraColumns=[percentileValueField],
  );


local percentileThresholdAlert(
  title,
  identifier,
  slackChannel='#mech_symp_alerts',
  scheduleHours=24,
  schedule={ interval: std.format('%dh', scheduleHours) },  // See https://www.elastic.co/guide/en/elasticsearch/reference/current/trigger-schedule.html for format
  keyField,
  elasticsearchIndexName,
  index='pubsub-rails-inf-gprd*',
  percentileValueField,
  percentile=95,
  thresholdValue,
  maxKeys=100,
  maxElementsReturned=5,
  minSampleSize=1000,
  issueSearchPrefix='https://gitlab.com/gitlab-org/gitlab/issues?scope=all&state=all&label_name[]=Mechanical%20Sympathy&search=',
  emoji=':rails:',
  unit='s',
  displayUnitDivisionFactor=1.0,
  queryFilters=[],
  includeRailsEndpointDashboardLink=false
      ) =

  local pathComponents = std.split(identifier, '/');
  local identifierShort = pathComponents[std.length(pathComponents) - 1];
  local percentileFormatted = '%.1f' % [percentile];


  // Link to the Rails Endpoint Dashboard
  local extraDetail = if includeRailsEndpointDashboardLink then
    |||
      :chart_with_upwards_trend: <%(link)s|Rails Endpoint Dashboard>
    ||| % {
      link: elasticsearchLinks.dashboards.railsEndpointDashboard('{{#url}}{{key}}{{/url}}', from='now-24', to='now'),
    }
  else
    '';

  {
    trigger: {
      schedule: schedule,
    },
    input: {
      search: {
        request: {
          search_type: 'query_then_fetch',
          indices: [
            index,
          ],
          types: [],
          body: {
            query: {
              bool: {
                must: [{
                  range: {
                    '@timestamp': {
                      gte: std.format('now-%dh', scheduleHours),
                      lte: 'now',
                    },
                  },
                }],
                filter: queryFilters,
              },
            },
            size: 0,
            aggs: {
              key: {
                terms: {
                  field: keyField,
                  size: maxKeys,
                  order: {
                    agg_sort_key: 'desc',
                  },
                },
                aggs: {
                  agg_sort_key: {
                    sum: {
                      field: percentileValueField,
                    },
                  },
                  max_value: {
                    max: {
                      field: percentileValueField,
                    },
                  },
                  agg_value: {
                    percentiles: {
                      field: percentileValueField,
                      percents: [percentile],
                      keyed: true,
                    },
                  },
                  feature_category_top_hit: {
                    top_hits: {
                      size: 1,
                      _source: {
                        includes: ['json.meta.feature_category'],
                      },
                    },
                  },
                  filter: {
                    bucket_selector: {
                      buckets_path: {
                        percentileValue: 'agg_value[%s]' % [percentileFormatted],
                        dc: '_count',  // Number of documents in this bucket
                      },
                      script: 'params.percentileValue > %(thresholdValue)g && params.dc >= %(minSampleSize)d' % { thresholdValue: thresholdValue, minSampleSize: minSampleSize },
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
    condition: painlessScript(conditionScript),
    transform: painlessScript(percentileThresholdTransformerScript(percentileFormatted, displayUnitDivisionFactor), { maxElementsReturned: maxElementsReturned }),
    actions: {
      'notify-slack': {
        slack: {
          account: 'gitlab_team',
          message: {
            from: 'ElasticCloud Watcher: ' + identifierShort,
            to: [
              slackChannel,
            ],
            text: title,
            dynamic_attachments: {
              list_path: 'ctx.payload.items',
              attachment_template: {
                title: emoji + ' {{key}}',
                text: |||
                  *p%(percentile)d*: {{ percentileFormattedValue }}%(unit)s, *max*: {{ maxValueFormatted }}%(unit)s, *samples* {{ doc_count }}
                  *Feature Category*: `{{feature_category}}`

                  :elasticsearch: <%(link)s|Kibana search> | :mag: <%(issueSearchLink)s|Search for issues>
                  %(extraDetail)s
                ||| % {
                  percentile: percentile,
                  link: searchLinkTemplate(elasticsearchIndexName, keyField, percentileValueField, thresholdValue, scheduleHours),
                  issueSearchLink: issueSearchPrefix + '{{#url}}{{key}}{{/url}}',
                  unit: unit,
                  extraDetail: extraDetail,
                },
              },
            },
          },
        },
      },
    },
  };

{
  percentileThresholdAlert:: percentileThresholdAlert,
}
