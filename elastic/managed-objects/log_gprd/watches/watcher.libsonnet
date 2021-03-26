local elasticsearchLinks = import 'elasticlinkbuilder/elasticsearch_links.libsonnet';

local conditionScript = |||
  ctx.payload.aggregations.key.buckets.length > 0
|||;

local percentileThresholdTransformerScript(percentileFormatted) =
  |||
    def items = ctx.payload.aggregations.key.buckets
      .collect(bucket -> {
        def v = bucket.agg_value.values['%(percentileFormatted)s'];

        [
        'key': bucket.key,
        'value': v,
        'percentileFormattedValue': new DecimalFormat("###,###.###").format(v)
        ]
      });

    items.sort((a,b) -> Double.compare(b.value, a.value));

    [
        'items': items.subList(0, items.length > params.maxElementsReturned ? params.maxElementsReturned : items.length)
    ];
  ||| % {
    percentileFormatted: percentileFormatted,
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
      elasticsearchLinks.matchFilter(keyField, '{{#url}}{{key}}{{/url}}'),
      elasticsearchLinks.rangeFilter(percentileValueField, lteValue=null, gteValue=thresholdValue),
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
  queryFilters=[],
      ) =

  local percentileFormatted = '%.1f' % [percentile];

  {
    trigger: {
      schedule: {
        interval: std.format('%dh', scheduleHours),
      },
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
                  agg_value: {
                    percentiles: {
                      field: percentileValueField,
                      percents: [percentile],
                      keyed: true,
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
    transform: painlessScript(percentileThresholdTransformerScript(percentileFormatted), { maxElementsReturned: maxElementsReturned }),
    actions: {
      'notify-slack': {
        slack: {
          account: 'gitlab_team',
          message: {
            from: 'ElasticCloud Watcher: ' + identifier,
            to: [
              slackChannel,
            ],
            text: title,
            dynamic_attachments: {
              list_path: 'ctx.payload.items',
              attachment_template: {
                title: emoji + ' {{key}}',
                text: |||
                  p%(percentile)d: {{ percentileFormattedValue }}%(unit)s.

                  :elasticsearch: <%(link)s|Kibana search>
                  :issue-created: <%(issueSearchLink)s|Search for issues>
                ||| % {
                  percentile: percentile,
                  link: searchLinkTemplate(elasticsearchIndexName, keyField, percentileValueField, thresholdValue, scheduleHours),
                  issueSearchLink: issueSearchPrefix + '{{#url}}{{key}}{{/url}}',
                  unit: unit,
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
