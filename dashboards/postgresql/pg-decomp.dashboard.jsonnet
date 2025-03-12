local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local graphPanel = grafana.graphPanel;

local panels = import 'gitlab-dashboards/panels.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';

local tableList = '(dast_pre_scan_verification_steps|dast_pre_scan_verifications|dast_profile_schedules|dast_profiles|dast_profiles_pipelines|dast_profiles_tags|dast_scanner_profiles|dast_scanner_profiles_builds|dast_site_profile_secret_variables|dast_site_profiles|dast_site_profiles_builds|dast_site_tokens|dast_site_validations|dast_sites|dependency_list_export_parts|dependency_list_exports|group_security_exclusions|project_security_exclusions|project_security_statistics|sbom_component_versions|sbom_components|sbom_occurrences|sbom_occurrences_vulnerabilities|sbom_source_packages|sbom_sources|security_findings|security_scans|vulnerabilities|vulnerability_archive_exports|vulnerability_archived_records|vulnerability_archives|vulnerability_export_parts|vulnerability_exports|vulnerability_external_issue_links|vulnerability_feedback|vulnerability_finding_evidences|vulnerability_finding_links|vulnerability_finding_signatures|vulnerability_findings_remediations|vulnerability_flags|vulnerability_historical_statistics|vulnerability_identifiers|vulnerability_issue_links|vulnerability_merge_request_links|vulnerability_namespace_historical_statistics|vulnerability_occurrence_identifiers|vulnerability_occurrences|vulnerability_reads|vulnerability_remediations|vulnerability_representation_information|vulnerability_scanners|vulnerability_severity_overrides|vulnerability_state_transitions|vulnerability_statistics|vulnerability_user_mentions)';

local sourceClusterNameTemplate = grafana.template.new(
  'src_cluster',
  '$PROMETHEUS_DS',
  'label_values(pg_settings_server_version_num, fqdn)',
  regex='/patroni-(\\w+)-/',
  current='main',
);

local destinationClusterNameTemplate = grafana.template.new(
  'dst_cluster',
  '$PROMETHEUS_DS',
  'label_values(pg_settings_server_version_num, fqdn)',
  regex='/patroni-(\\w+)-/',
  current='sec',
);

// Both clusters need to be the same Major version of PG
local versionTemplate = grafana.template.new(
  'version',
  '$PROMETHEUS_DS',
  'query_result(min by(__name__) (pg_settings_server_version_num{fqdn=~"patroni-${src_cluster}.*"}))',
  regex='/.*\\v(\\d{2})/',
  refresh='load',
  sort=1,
);

local logicalReplicationLag =
  panels.generalGraphPanel('Logical replication lag (all slots in $environment)', fill=10, decimals=1, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='bytes',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        sum(pg_replication_slots_confirmed_flush_lsn_bytes{env="$environment", slot_type="logical"}) by (fqdn, slot_type, slot_name)
      |||,
    ),
  );

local context =
  panels.generalTextPanel('Context', content='# **$environment** **$src_cluster** **$dst_cluster**', transparent=true);

local usefulLinks =
  panels.generalTextPanel('Useful links',
                          content='\n- [Ansible playbooks](https://gitlab.com/gitlab-com/gl-infra/db-migration/-/tree/master/pg-physical-to-logical)\n- [Inventory in Ansible](https://gitlab.com/gitlab-com/gl-infra/db-migration/-/tree/master/pg-physical-to-logical/inventory)\n- [CR template](https://gitlab.com/gitlab-com/gl-infra/db-migration/-/blob/master/.gitlab/issue_templates/decomposition.md) (individual CRs are to be located at ops.gitlab.net)\n- [Diagram illustrating the process](https://gitlab.com/gitlab-com/gl-infra/db-migration/-/blob/master/.gitlab/issue_templates/decomposition.md#high-level-overview)\n    ',
                          transparent=true);

local clusterLeft =
  panels.generalTextPanel('Cluster on the left', content='🏹 Source cluster: ${src_cluster}, Ubuntu 20.04', transparent=true);
local clusterRight =
  panels.generalTextPanel('Cluster on the right', content='🎯 Target cluster: ${dst_cluster} ', transparent=true);

local replicationLagSourceSeconds =
  panels.generalGraphPanel('🏹 🏃🏻‍♀️ Physical replication lag on source standbys, in seconds', decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='seconds',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        sum(pg_replication_lag{env="$environment", fqdn=~"patroni-${src_cluster}-v${version}.*"}) by (fqdn)
      |||,
    ),
  );

local replicationLagTargetSeconds =
  panels.generalGraphPanel('🎯 🏃🏻‍♀️ Physical replication lag on target standbys, in seconds', decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='seconds',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        sum(pg_replication_lag{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*"}) by (fqdn)
      |||,
    ),
  );

local replicationLagSourceBytes =
  panels.generalGraphPanel('🏹 🏃🏻‍♀️ Physical replication lag on source standbys, in bytes', decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='bytes',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        sum(postgres:pg_replication_lag_bytes{env="$environment", fqdn=~"(patroni-${src_cluster}-v${version}|patroni-${src_cluster}-[0-9]+).*"}) by (fqdn)
      |||,
    ),
  );

local replicationLagTargetBytes =
  panels.generalGraphPanel('🎯 🏃🏻‍♀️ Physical replication lag on target standbys, in bytes', decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='bytes',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        sum(postgres:pg_replication_lag_bytes{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*"}) by (fqdn)
      |||,
    ),
  );

local sourceLeaderTPSCommits =
  panels.generalGraphPanel('🏹 🥇 Source leader TPS (commits) ✅', fill=10, decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='ops/sec',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        (sum(irate(pg_stat_database_xact_commit{env="$environment", fqdn=~"(patroni-${src_cluster}-v${version}|patroni-${src_cluster}-[0-9]+).*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==0
      |||,
    ),
  );

local targetLeaderTPSCommits =
  panels.generalGraphPanel('🎯 🥇 Target leader TPS (commits) ✅', fill=10, decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='ops/sec',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        (sum(irate(pg_stat_database_xact_commit{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==0
      |||,
    ),
  );

local sourceStandbysTPSCommits =
  panels.generalGraphPanel('🏹 👥 Source standbys TPS (commits) ✅', decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='ops/sec',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        (sum(irate(pg_stat_database_xact_commit{env="$environment", fqdn=~"(patroni-${src_cluster}-v${version}|patroni-${src_cluster}-[0-9]+).*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
      |||,
    ),
  );

local targetStandbysTPSCommits =
  panels.generalGraphPanel('🎯 👥 Target standbys TPS (commits) ✅', decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='ops/sec',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        (sum(irate(pg_stat_database_xact_commit{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
      |||,
    ),
  );

local sourceLeaderRollbackTPSErrors =
  panels.generalGraphPanel('🏹 🥇 Source leader rollback TPS – ERRORS ❌', decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='err/s',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        (sum(irate(pg_stat_database_xact_rollback{env="$environment", fqdn=~"(patroni-${src_cluster}-v${version}|patroni-${src_cluster}-[0-9]+).*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==0
      |||,
    ),
  );

local targetLeaderRollbackTPSErrors =
  panels.generalGraphPanel('🎯 🥇 Target leader rollback TPS – ERRORS ❌', decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='err/s',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        (sum(irate(pg_stat_database_xact_rollback{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==0
      |||,
    ),
  );

local sourceStandbysRollbackTPSErrors =
  panels.generalGraphPanel('🏹 👥 Source standbys roolback TPS – ERRORS ❌', decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='err/s',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        (sum(irate(pg_stat_database_xact_rollback{env="$environment", fqdn=~"(patroni-${src_cluster}-v${version}|patroni-${src_cluster}-[0-9]+).*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
      |||,
    ),
  );

local targetStandbysRollbackTPSErrors =
  panels.generalGraphPanel('🎯 👥 Target standbys rollback TPS – ERRORS ❌', decimals=3, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='err/s',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        (sum(irate(pg_stat_database_xact_rollback{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
      |||,
    ),
  );

local sourceWritesTuple =
  panels.generalGraphPanel('🏹 Source writes (tuple ins/upd/del)', decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='ops/s',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        sum(irate(pg_stat_user_tables_n_tup_ins{env="$environment", fqdn=~"(patroni-${src_cluster}-v${version}|patroni-${src_cluster}-[0-9]+).*"}[1m])
        +
        irate(pg_stat_user_tables_n_tup_del{env="$environment", fqdn=~"(patroni-${src_cluster}-v${version}|patroni-${src_cluster}-[0-9]+).*"}[1m])
        +
        irate(pg_stat_user_tables_n_tup_upd{env="$environment", fqdn=~"(patroni-${src_cluster}-v${version}|patroni-${src_cluster}-[0-9]+).*"}[1m])) by (instance)
        and on(instance) pg_replication_is_replica==0
      |||,
    ),
  );

local targetWritesTuple =
  panels.generalGraphPanel('🎯 Target writes (tuple ins/upd/del)', decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='ops/s',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        sum(irate(pg_stat_user_tables_n_tup_ins{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*"}[1m])
        +
        irate(pg_stat_user_tables_n_tup_del{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*"}[1m])
        +
        irate(pg_stat_user_tables_n_tup_upd{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*"}[1m])) by (instance)
        and on(instance) pg_replication_is_replica==0
      |||,
    ),
  );

local sourceWritesTupleTables =
  panels.generalGraphPanel('🏹 Source writes (tuple ins/upd/del) for Decomp Tables', decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='ops/s',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(std.format(
      |||
        sum(irate(pg_stat_user_tables_n_tup_ins{env="$environment", fqdn=~"(patroni-${src_cluster}-v${version}|patroni-${src_cluster}-[0-9]+).*", relname=~"%s"}[1m])
        +
        irate(pg_stat_user_tables_n_tup_del{env="$environment", fqdn=~"(patroni-${src_cluster}-v${version}|patroni-${src_cluster}-[0-9]+).*", relname=~"%s"}[1m])
        +
        irate(pg_stat_user_tables_n_tup_upd{env="$environment", fqdn=~"(patroni-${src_cluster}-v${version}|patroni-${src_cluster}-[0-9]+).*", relname=~"%s"}[1m])) by (instance)
        and on(instance) pg_replication_is_replica==0
      |||, tableList, tableList, tableList
      ),
    ),
  );

local targetWritesTupleTables =
  panels.generalGraphPanel('🎯 Target writes (tuple ins/upd/del) for Decomp Tables', decimals=2, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='ops/s',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        sum(irate(pg_stat_user_tables_n_tup_ins{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*", relname=~"${tableList}"}[1m])
        +
        irate(pg_stat_user_tables_n_tup_del{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*", relname=~"${tableList}"}[1m])
        +
        irate(pg_stat_user_tables_n_tup_upd{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*", relname=~"${tableList}"}[1m])) by (instance)
        and on(instance) pg_replication_is_replica==0
      |||,
    ),
  );

local sourceIndexTupleFetches =
  panels.generalGraphPanel('🏹 Source index tuple fetches', decimals=3, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='ops/s',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        (sum(rate(pg_stat_user_tables_idx_tup_fetch{env="$environment", fqdn=~"(patroni-${src_cluster}-v${version}|patroni-${src_cluster}-[0-9]+).*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
      |||,
    ),
  );

local targetIndexTupleFetches =
  panels.generalGraphPanel('🎯 Target index tuple fetches', decimals=3, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='ops/s',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        (sum(rate(pg_stat_user_tables_idx_tup_fetch{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
      |||,
    ),
  );

local sourceSeqTupleReads =
  panels.generalGraphPanel('🏹 Source seq tuple reads', decimals=3, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='ops/s',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        (sum(rate(pg_stat_user_tables_seq_tup_read{env="$environment", fqdn=~"(patroni-${src_cluster}-v${version}|patroni-${src_cluster}-[0-9]+).*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
      |||,
    ),
  );

local targetSeqTupleReads =
  panels.generalGraphPanel('🎯 Target seq tuple reads', decimals=3, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='ops/s',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        (sum(rate(pg_stat_user_tables_seq_tup_read{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
      |||,
    ),
  );

local sourceSeqTupleReadsTable =
  panels.generalGraphPanel('🏹 Source seq tuple reads for Decomp Tables', decimals=3, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='ops/s',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        (sum(rate(pg_stat_user_tables_seq_tup_read{env="$environment", fqdn=~"(patroni-${src_cluster}-v${version}|patroni-${src_cluster}-[0-9]+).*", relname=~"${tableList}"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
      |||,
    ),
  );

local targetSeqTupleReadsTable =
  panels.generalGraphPanel('🎯 Target seq tuple reads for Decomp Tables', decimals=3, legend_show=true, legend_min=false, legend_current=false)
  .resetYaxes()
  .addYaxis(
    format='ops/s',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  )
  .addTarget(
    promQuery.target(
      |||
        (sum(rate(pg_stat_user_tables_seq_tup_read{env="$environment", fqdn=~"patroni-${dst_cluster}-v${version}-.*", relname=~"${tableList}"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
      |||,
    ),
  );

basic.dashboard(
  'Database Decomposition using logical',
  tags=['postgresql'],
)

.addTemplate(sourceClusterNameTemplate)
.addTemplate(destinationClusterNameTemplate)
.addTemplate(versionTemplate)
.addPanel(context, gridPos={ x: 0, y: 0, w: 6, h: 7 })
.addPanel(clusterLeft, gridPos={ x: 0, y: 7, w: 6, h: 3 })
.addPanel(logicalReplicationLag, gridPos={ x: 6, y: 0, w: 12, h: 10 })
.addPanel(usefulLinks, gridPos={ x: 18, y: 0, w: 6, h: 7 })
.addPanel(clusterRight, gridPos={ x: 18, y: 7, w: 6, h: 3 })
.addPanel(
  row.new(title='Physical lags', collapse=true)
  .addPanel(replicationLagSourceSeconds, gridPos={ x: 0, y: 11, w: 12, h: 10 })
  .addPanel(replicationLagTargetSeconds, gridPos={ x: 12, y: 11, w: 12, h: 10 })
  .addPanel(replicationLagSourceBytes, gridPos={ x: 0, y: 21, w: 12, h: 10 })
  .addPanel(replicationLagTargetBytes, gridPos={ x: 12, y: 21, w: 12, h: 10 }),
  gridPos={
    x: 0,
    y: 11,
    w: 24,
    h: 1,
  }
)
.addPanel(
  row.new(title='TPS (commits)', collapse=true)
  .addPanel(sourceLeaderTPSCommits, gridPos={ x: 0, y: 12, w: 12, h: 8 })
  .addPanel(targetLeaderTPSCommits, gridPos={ x: 12, y: 12, w: 12, h: 8 })
  .addPanel(sourceStandbysTPSCommits, gridPos={ x: 0, y: 20, w: 12, h: 8 })
  .addPanel(targetStandbysTPSCommits, gridPos={ x: 12, y: 20, w: 12, h: 8 }),
  gridPos={
    x: 0,
    y: 12,
    w: 24,
    h: 1,
  }
)
.addPanel(
  row.new(title='TPS rollbacks – ERROR RATES', collapse=true)
  .addPanel(sourceLeaderRollbackTPSErrors, gridPos={ x: 0, y: 13, w: 12, h: 8 })
  .addPanel(targetLeaderRollbackTPSErrors, gridPos={ x: 12, y: 13, w: 12, h: 8 })
  .addPanel(sourceStandbysRollbackTPSErrors, gridPos={ x: 0, y: 21, w: 12, h: 8 })
  .addPanel(targetStandbysRollbackTPSErrors, gridPos={ x: 12, y: 21, w: 12, h: 8 }),
  gridPos={
    x: 0,
    y: 13,
    w: 24,
    h: 1,
  }
)
.addPanel(
  row.new(title='Tuple stats: ins/upd/del, index fetches, seq reads', collapse=true)
  .addPanel(sourceWritesTuple, gridPos={ x: 0, y: 14, w: 12, h: 8 })
  .addPanel(targetWritesTuple, gridPos={ x: 12, y: 14, w: 12, h: 8 })
  .addPanel(sourceWritesTupleTables, gridPos={ x: 0, y: 22, w: 12, h: 8 })
  .addPanel(targetWritesTupleTables, gridPos={ x: 12, y: 22, w: 12, h: 8 })
  .addPanel(sourceIndexTupleFetches, gridPos={ x: 0, y: 30, w: 12, h: 8 })
  .addPanel(targetIndexTupleFetches, gridPos={ x: 12, y: 30, w: 12, h: 8 })
  .addPanel(sourceSeqTupleReads, gridPos={ x: 0, y: 38, w: 12, h: 8 })
  .addPanel(targetSeqTupleReads, gridPos={ x: 12, y: 38, w: 12, h: 8 })
  .addPanel(sourceSeqTupleReadsTable, gridPos={ x: 0, y: 46, w: 12, h: 8 })
  .addPanel(targetSeqTupleReadsTable, gridPos={ x: 12, y: 46, w: 12, h: 8 }),
  gridPos={
    x: 0,
    y: 14,
    w: 24,
    h: 1,
  }
)
