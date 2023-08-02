local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local toolingLinkDefinition = (import 'toolinglinks/tooling_link_definition.libsonnet').toolingLinkDefinition({ tool:: 'kibana', type:: 'log' });
local elasticsearchLinks = import 'elasticlinkbuilder/elasticsearch_links.libsonnet';
local matching = import 'elasticlinkbuilder/matching.libsonnet';

{
  shardWorkloads(querySelector, startRow, datalink=null)::
    local formatConfig = {
      querySelector: querySelector,
    };

    local panels = [
      basic.saturationTimeseries(
        title='Sidekiq Worker Saturation by Shard',
        description='Shows sidekiq worker saturation. Once saturated, all sidekiq workers will be busy processing jobs, and any new jobs that arrive will queue. Lower is better.',
        query=|||
          max by(shard, environment, type, stage) (
            sum by (fqdn, instance, shard, environment, type, stage) (sidekiq_running_jobs{%(querySelector)s})
            /
            sum by (fqdn, instance, shard, environment, type, stage) (sidekiq_concurrency{%(querySelector)s})
          )
        ||| % formatConfig,
        legendFormat='{{ shard }}',
        intervalFactor=1,
        linewidth=2,
      ),
      basic.saturationTimeseries(
        'Node Average CPU Utilization per Shard',
        description='The maximum utilization of a single core on each node. Lower is better',
        query=|||
          avg(1 - rate(node_cpu_seconds_total{%(querySelector)s, mode="idle"}[$__interval])) by (shard)
        ||| % formatConfig,
        legendFormat='{{ shard }}',
        legend_show=true,
        linewidth=2
      ),
      basic.saturationTimeseries(
        'Node Maximum Single Core Utilization per Shard',
        description='The maximum utilization of a single core on each node. Lower is better',
        query=|||
          max(1 - rate(node_cpu_seconds_total{%(querySelector)s, mode="idle"}[$__interval])) by (shard)
        ||| % formatConfig,
        legendFormat='{{ shard }}',
        legend_show=true,
        linewidth=2
      ),
      basic.saturationTimeseries(
        title='Maximum Memory Utilization per Shard',
        description='Memory utilization. Lower is better.',
        query=|||
          max by (shard) (
            instance:node_memory_utilization:ratio{%(querySelector)s}
          )
        ||| % formatConfig,
        legendFormat='{{ shard }}',
        interval='1m',
        intervalFactor=1,
        legend_show=true,
        linewidth=2
      ),
    ];

    local panelsWithDataLink =
      if datalink != null then
        [p.addDataLink(datalink) for p in panels]
      else
        panels;

    layout.grid(panelsWithDataLink, cols=2, rowHeight=10, startRow=startRow),

  // matcherField is the field used from template variable.
  latencyKibanaViz(index, title, matcherField, percentile, templateField=matcherField)::
    function(options)
      [
        toolingLinkDefinition({
          title: title,
          url: elasticsearchLinks.buildElasticLinePercentileVizURL(
            index,
            [matching.matchRegexFilter('json.%s.keyword' % matcherField, '${%s:regex}' % templateField)],
            splitSeries=true,
            percentile=percentile
          ),
          type:: 'chart',
        }),
      ],
}
