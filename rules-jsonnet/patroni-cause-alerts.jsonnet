local alerts = import 'alerts/alerts.libsonnet';
local elasticsearchLinks = import 'elasticlinkbuilder/elasticsearch_links.libsonnet';
local aggregations = import 'promql/aggregations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local aggregationLabelsForPrimary = ['environment', 'tier', 'type', 'fqdn'];
local aggregationLabelsForReplicas = ['environment', 'tier', 'type'];
local selector = { type: 'patroni' };

local alertExpr(aggregationLabels, selector, replica, threshold) =
  local aggregationLabelsWithRelName = aggregationLabels + ['relname'];

  |||
    (
      sum by (%(aggregationLabelsWithRelName)s) (
        rate(pg_stat_user_tables_idx_tup_fetch{%(selector)s}[5m])
        and on(job, instance)
        pg_replication_is_replica == %(replica)s
      )
      / ignoring(relname) group_left()
        sum by (%(aggregationLabels)s) (
          rate(pg_stat_user_tables_idx_tup_fetch{%(selector)s}[5m])
          and on(job, instance)
          pg_replication_is_replica == %(replica)s
      )
    ) > %(threshold)g
  ||| % {
    aggregationLabelsWithRelName: aggregations.serialize(aggregationLabelsWithRelName),
    aggregationLabels: aggregations.serialize(aggregationLabels),
    selector: selectors.serializeHash(selector),
    replica: if replica then '1' else '0',
    threshold: threshold,
  };

local hotspotTupleAlert(alertName, periodFor, warning, replica) =
  local threshold = 0.5;  // 50%
  local aggregationLabels = if replica then aggregationLabelsForReplicas else aggregationLabelsForPrimary;

  local elasticFilters = [
    elasticsearchLinks.matchFilter('json.sql', '{{$labels.relname}}'),
  ] + (
    if replica then
      []
    else
      [elasticsearchLinks.matchFilter('json.fqdn', '{{$labels.fqdn}}')]
  );


  local formatConfig = {
    postgresLocation: if replica then 'postgres replicas' else 'primary `{{ $labels.fqdn }}`',
    thresholdPercent: threshold * 100,
    kibanaUrl: elasticsearchLinks.buildElasticDiscoverSearchQueryURL('postgres', elasticFilters, timeRange=''),
  };

  alerts.processAlertRule({
    alert: alertName,
    expr: alertExpr(aggregationLabels=aggregationLabels, selector=selector, replica=replica, threshold=threshold),
    'for': periodFor,
    labels: {
      team: 'rapid-action-intercom',
      severity: if warning then 's4' else 's1',
      alert_type: 'cause',
      [if !warning then 'pager']: 'pagerduty',
      runbook: 'docs/patroni/rails-sql-apdex-slow.md',
    },
    annotations: {
      title: 'Hot spot tuple fetches on the postgres %(postgresLocation)s in the `{{ $labels.relname }}` table, `{{ $labels.relname }}`.' % formatConfig,
      description: |||
        More than %(thresholdPercent)g%% of all tuple fetches on postgres %(postgresLocation)s are for a single table.

        This may indicate that the query optimizer is using incorrect statistics to execute a query.

        This could be due to vacuum and analyze commands (issued either automatically or manually) against this table or closely related table.
        As a new step, check which tables were analyzed and vacuumed immediately prior to this incident.

        <%(kibanaUrl)s|postgres slowlog in Kibana>

        Previous incidents of this type include <https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2885> and
        <https://gitlab.com/gitlab-com/gl-infra/production/-/issues/3875>.
      ||| % formatConfig,
      grafana_dashboard_id: if replica then 'alerts-pg_user_tables_replica/alerts-pg-user-table-alerts-replicas' else 'alerts-pg_user_tables_primary/alerts-pg-user-table-alerts-primary',
      grafana_min_zoom_hours: '6',
      grafana_panel_id: '2',
      grafana_variables: aggregations.serialize(aggregationLabels + ['relname']),
    },
  });

local rules = {
  groups: [
    {
      name: 'patroni_cause_alerts',
      rules: [
        hotspotTupleAlert(
          'PostgreSQL_HotSpotTupleFetchingPrimary',
          '10m',
          warning=true,
          replica=false
        ),
        hotspotTupleAlert(
          'PostgreSQL_HotSpotTupleFetchingReplicas',
          '10m',
          warning=true,
          replica=true
        ),

        // Long running transaction alert
        alerts.processAlertRule({
          alert: 'PatroniLongRunningTransactionDetected',
          expr: |||
            topk by (environment, type, stage, shard) (1,
              max by (environment, type, stage, shard, application, endpoint, fqdn) (
                pg_stat_activity_marginalia_sampler_max_tx_age_in_seconds{
                  type="patroni",
                  command!="vacuum",
                  command!="autovacuum",
                  command!~"[cC][rR][eE][aA][tT][eE]",
                  command!~"[aA][nN][aA][lL][yY][zZ][eE]",
                  command!~"[rR][eE][iI][nN][dD][eE][xX]",
                }
              )
              > 540
            )
          |||,
          'for': '1m',
          labels: {
            team: 'sre_datastores',
            severity: 's2',
            alert_type: 'cause',
            pager: 'pagerduty',
            runbook: 'docs/patroni/postgres.md#tables-with-a-large-amount-of-dead-tuples',
          },
          annotations: {
            title: 'Transactions detected that have been running on `{{ $labels.fqdn }}` for more than 10m',
            description: |||
              Endpoint `{{ $labels.endpoint }}` on `{{ $labels.application }}` is executing a transaction that has been running
              for more than 10m. This could lead to dead-tuples and performance degradation in our Patroni fleet.

              Ideally, no transaction should remain open for more than a few seconds.

              <%(kibanaUrl)s|Check the slowlog for changes in the usual trends>.
            ||| % {
              kibanaUrl: elasticsearchLinks.buildElasticLineCountVizURL('postgres', [], splitSeries=true, timeRange=''),
            },
            grafana_dashboard_id: 'alerts-long_running_transactions/alerts-long-running-transactions',
            grafana_min_zoom_hours: '6',
            grafana_variables: 'environment',
          },
        }),
      ],
    },
  ],
};

{
  'patroni-cause-alerts.yml': std.manifestYamlDoc(rules),
}
