local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local selector = { env: '$environment', stage: '$stage', type: 'kas' };
local selectorString = selectors.serializeHash(selector);

basic.dashboard(
  'Redis metrics',
  tags=[
    'kas',
  ],
)
.addTemplate(templates.stage)
.addPanels(
  layout.titleRowWithPanels(
    'Rueidis metrics',
    layout.grid([
      basic.multiTimeseries(
        title='Dial Latency',
        description='Rueidis dial latency in seconds',
        queries=[{
          legendFormat: 'p' + percentile,
          query: |||
            histogram_quantile(%(percentile)g, sum by (le) (
            rate(rueidis_dial_latency_seconds_bucket{%(selector)s}[$__rate_interval]))
            )
          ||| % { selector: selectorString, percentile: percentile / 100 },
        } for percentile in [50, 90, 95, 99]],
        format='s',
        interval='1m',
        intervalFactor=2,
      ),
      basic.timeseries(
        title='Number of connections',
        description='Rueidis number of connections',
        query=|||
          sum (
            rueidis_dial_conns{%s}
          )
        ||| % selectorString,
        intervalFactor=2,
        legend_show=false,
      ),
      basic.multiTimeseries(
        title='Total dial attemps and dial successes',
        description='Rueidis total number of dial attempts and dial successes',
        queries=[
          {
            query: |||
              sum (
                increase(rueidis_dial_attempt_total{%s}[$__rate_interval])
              )
            ||| % selectorString,
            legendFormat: 'Attempts',
          },
          {
            query: |||
              sum (
                increase(rueidis_dial_success_total{%s}[$__rate_interval])
              )
            ||| % selectorString,
            legendFormat: 'Success',
          },
        ],
        legend_show=true,
        linewidth=2,
        stack=false,
      ),
      basic.timeseries(
        title='Total dial failures',
        description='Rueidis total number of dial failures, calculated by `attempts - success`.',
        query=|||
          sum (
            increase(rueidis_dial_attempt_total{%(selector)s}[$__rate_interval])
          )
          -
          sum (
            increase(rueidis_dial_success_total{%(selector)s}[$__rate_interval])
          )
        ||| % { selector: selectorString },
        legend_show=false,
        intervalFactor=2,
      ),
    ], startRow=1000),
    collapse=false,
    startRow=0
  )
)
.addPanels(
  layout.titleRowWithPanels(
    'KAS Redis client metrics',
    layout.grid([
      basic.multiTimeseries(
        title="Number of %(displayName)s agent hash keys GC'ed" % { displayName: expiringHash.displayName },
        description='`%(name)s` - Expiring Hash: number of deleted keys during GC and ScanAndGC' % { name: expiringHash.name },
        queries=[
          {
            query: |||
              sum ( increase(redis_expiring_hash_api_scan_and_gc_deleted_keys_count_total{expiring_hash_name="%(name)s", %(selector)s}[$__rate_interval]) )
            ||| % { name: expiringHash.name, selector: selectorString },
            legendFormat: 'ScanAndGC',
          },
          {
            query: |||
              sum ( increase(redis_expiring_hash_gc_deleted_keys_count_total{expiring_hash_name="%(name)s", %(selector)s}[$__rate_interval]) )
            ||| % { name: expiringHash.name, selector: selectorString },
            legendFormat: 'GC',
          },
        ],
        legend_show=true,
        linewidth=2,
        stack=false,
      )
      for expiringHash in [
        { name: 'tunnels_by_agent_id', displayName: 'tunnels_by_agent_id' },
        { name: 'connected_agents', displayName: 'connected agents' },
        { name: 'connections_by_agent_id', displayName: 'connections by agent id' },
        { name: 'connections_by_project_id', displayName: 'connections by project id' },
      ]
    ], startRow=3000),
    collapse=false,
    startRow=2000
  )
)
