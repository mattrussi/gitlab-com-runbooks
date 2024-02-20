local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local row = grafana.row;
local graphPanel = grafana.graphPanel;

local panels = import 'gitlab-dashboards/panels.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';

local clusterNameTemplate = grafana.template.custom(
    'cluster',
    'main,ci,registry',
    current='main',
);

local logicalReplicationLag =
    panels.generalGraphPanel('Logical replication lag (all slots in $environment)', fill=10, decimals=1, legend_show=true,legend_min=false,legend_current=false)
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
    panels.generalTextPanel('Context',content='# **$environment** **$cluster**', transparent=true);

local usefulLinks =
    panels.generalTextPanel('Useful links',
    content='
- [Ansible playbooks](https://gitlab.com/gitlab-com/gl-infra/db-migration/-/tree/master/pg-upgrade-logical)
- [Inventory in Ansible](https://gitlab.com/gitlab-com/gl-infra/db-migration/-/tree/master/pg-upgrade-logical/inventory)
- [CR template](https://gitlab.com/gitlab-com/gl-infra/db-migration/-/blob/master/.gitlab/issue_templates/pg14_upgrade.md) (individual CRs are to be located at ops.gitlab.net)
- [Diagram illustrating the process](https://gitlab.com/gitlab-com/gl-infra/db-migration/-/blob/master/.gitlab/issue_templates/pg14_upgrade.md#high-level-overview)
    ', transparent=true);

local clusterLeft =
    panels.generalTextPanel('Cluster on the left',content='🏹 Source cluster: PG12, Ubuntu 20.04 (prefixes contain hard-coded `v12` and/or `2004`)', transparent=true);

local clusterRight =
    panels.generalTextPanel('Cluster on the right',content='🎯 Target cluster: PG14 (prefixes contain hard-coded `v14`)', transparent=true);

local replicationLagSourceSeconds =
    panels.generalGraphPanel('🏹 🏃🏻‍♀️ Physical replication lag on source standbys, in seconds', decimals=2, legend_show=true,legend_min=false,legend_current=false)
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
                    sum(pg_replication_lag{env="$environment", fqdn=~"(patroni-${cluster}-2004|patroni-v12-${cluster})-.*"}) by (fqdn)
                |||,
            ),
        );

local replicationLagTargetSeconds =
    panels.generalGraphPanel('🎯 🏃🏻‍♀️ Physical replication lag on target standbys, in seconds', decimals=2, legend_show=true,legend_min=false,legend_current=false)
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
                    sum(pg_replication_lag{env="$environment", fqdn=~"patroni-${cluster}-v14-.*"}) by (fqdn)
                |||,
            ),
        );

local replicationLagSourceBytes =
    panels.generalGraphPanel('🏹 🏃🏻‍♀️ Physical replication lag on source standbys, in bytes', decimals=2, legend_show=true,legend_min=false,legend_current=false)
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
                    sum(postgres:pg_replication_lag_bytes{env="$environment", fqdn=~"(patroni-${cluster}-2004|patroni-v12-${cluster})-.*"}) by (fqdn)
                |||,
            ),
        );

local replicationLagTargetBytes =
    panels.generalGraphPanel('🎯 🏃🏻‍♀️ Physical replication lag on target standbys, in bytes', decimals=2, legend_show=true,legend_min=false,legend_current=false)
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
                    sum(postgres:pg_replication_lag_bytes{env="$environment", fqdn=~"patroni-${cluster}-v14-.*"}) by (fqdn)
                |||,
            ),
        );

local sourceLeaderTPSCommits =
    panels.generalGraphPanel('🏹 🥇 Source leader TPS (commits) ✅', fill=10, decimals=2, legend_show=true,legend_min=false,legend_current=false)
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
                    (sum(irate(pg_stat_database_xact_commit{env="$environment", fqdn=~"(patroni-${cluster}-2004|patroni-v12-${cluster})-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==0
                |||,
            ),
        );

local targetLeaderTPSCommits =
    panels.generalGraphPanel('🎯 🥇 Target leader TPS (commits) ✅', fill=10, decimals=2, legend_show=true,legend_min=false,legend_current=false)
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
                    (sum(irate(pg_stat_database_xact_commit{env="$environment", fqdn=~"patroni-${cluster}-v14-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==0
                |||,
            ),
        );

local sourceStandbysTPSCommits =
    panels.generalGraphPanel('🏹 👥 Source standbys TPS (commits) ✅', decimals=2, legend_show=true,legend_min=false,legend_current=false)
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
                    (sum(irate(pg_stat_database_xact_commit{env="$environment", fqdn=~"(patroni-${cluster}-2004|patroni-v12-${cluster})-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
                |||,
            ),
        );

local targetStandbysTPSCommits =
    panels.generalGraphPanel('🎯 👥 Target standbys TPS (commits) ✅', decimals=2, legend_show=true,legend_min=false,legend_current=false)
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
                    (sum(irate(pg_stat_database_xact_commit{env="$environment", fqdn=~"patroni-${cluster}-v14-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
                |||,
            ),
        );

local sourceLeaderRollbackTPSErrors =
    panels.generalGraphPanel('🏹 🥇 Source leader rollback TPS – ERRORS ❌', decimals=2, legend_show=true,legend_min=false,legend_current=false)
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
                    (sum(irate(pg_stat_database_xact_rollback{env="$environment", fqdn=~"(patroni-${cluster}-2004|patroni-v12-${cluster})-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==0
                |||,
            ),
        );

local targetLeaderRollbackTPSErrors =
    panels.generalGraphPanel('🎯 🥇 Target leader rollback TPS – ERRORS ❌', decimals=2, legend_show=true,legend_min=false,legend_current=false)
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
                    (sum(irate(pg_stat_database_xact_rollback{env="$environment", fqdn=~"patroni-${cluster}-v14-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==0
                |||,
            ),
        );

local sourceStandbysRollbackTPSErrors =
    panels.generalGraphPanel('🏹 👥 Source standbys roolback TPS – ERRORS ❌', decimals=2, legend_show=true,legend_min=false,legend_current=false)
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
                    (sum(irate(pg_stat_database_xact_rollback{env="$environment", fqdn=~"(patroni-${cluster}-2004|patroni-v12-${cluster})-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
                |||,
            ),
        );

local targetStandbysRollbackTPSErrors =
    panels.generalGraphPanel('🎯 👥 Target standbys rollback TPS – ERRORS ❌', decimals=3, legend_show=true,legend_min=false,legend_current=false)
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
                    (sum(irate(pg_stat_database_xact_rollback{env="$environment", fqdn=~"patroni-${cluster}-v14-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
                |||,
            ),
        );

local sourceWritesTuple =
    panels.generalGraphPanel('🏹 Source writes (tuple ins/upd/del)', decimals=2, legend_show=true,legend_min=false,legend_current=false)
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
                    sum(irate(pg_stat_user_tables_n_tup_ins{env="$environment", fqdn=~"(patroni-${cluster}-2004|patroni-v12-${cluster})-.*"}[1m])
                    +
                    irate(pg_stat_user_tables_n_tup_del{env="$environment", fqdn=~"(patroni-${cluster}-2004|patroni-v12-${cluster})-.*"}[1m])
                    +
                    irate(pg_stat_user_tables_n_tup_upd{env="$environment", fqdn=~"(patroni-${cluster}-2004|patroni-v12-${cluster})-.*"}[1m])) by (instance)
                    and on(instance) pg_replication_is_replica==0
                |||,
            ),
        );

local targetWritesTuple =
    panels.generalGraphPanel('🎯 Target writes (tuple ins/upd/del)', decimals=2, legend_show=true,legend_min=false,legend_current=false)
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
                    sum(irate(pg_stat_user_tables_n_tup_ins{env="$environment", fqdn=~"patroni-${cluster}-v14-.*"}[1m])
                    +
                    irate(pg_stat_user_tables_n_tup_del{env="$environment", fqdn=~"patroni-${cluster}-v14-.*"}[1m])
                    +
                    irate(pg_stat_user_tables_n_tup_upd{env="$environment", fqdn=~"patroni-${cluster}-v14-.*"}[1m])) by (instance)
                    and on(instance) pg_replication_is_replica==0
                |||,
            ),
        );

local sourceIndexTupleFetches =
    panels.generalGraphPanel('🏹 Source index tuple fetches', decimals=3, legend_show=true,legend_min=false,legend_current=false)
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
                    (sum(rate(pg_stat_user_tables_idx_tup_fetch{env="$environment", fqdn=~"(patroni-${cluster}-2004|patroni-v12-${cluster})-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
                |||,
            ),
        );

local targetIndexTupleFetches =
    panels.generalGraphPanel('🎯 Target index tuple fetches', decimals=3, legend_show=true,legend_min=false,legend_current=false)
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
                    (sum(rate(pg_stat_user_tables_idx_tup_fetch{env="$environment", fqdn=~"patroni-${cluster}-v14-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
                |||,
            ),
        );

local sourceSeqTupleReads =
    panels.generalGraphPanel('🏹 Source seq tuple reads', decimals=3, legend_show=true,legend_min=false,legend_current=false)
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
                    (sum(rate(pg_stat_user_tables_seq_tup_read{env="$environment", fqdn=~"(patroni-${cluster}-2004|patroni-v12-${cluster})-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
                |||,
            ),
        );

local targetSeqTupleReads =
    panels.generalGraphPanel('🎯 Target seq tuple reads', decimals=3, legend_show=true,legend_min=false,legend_current=false)
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
                    (sum(rate(pg_stat_user_tables_seq_tup_read{env="$environment", fqdn=~"patroni-${cluster}-v14-.*"}[1m])) by (instance)) and on(instance) pg_replication_is_replica==1
                |||,
            ),
        );

basic.dashboard(
    'Postgres upgrade using logical',
    tags=['postgresql'],
)

.addTemplate(clusterNameTemplate)
.addPanel(context,gridPos={'x':0,'y':0,'w':6,'h':7})
.addPanel(clusterLeft,gridPos={'x':0,'y':7,'w':6,'h':3})
.addPanel(logicalReplicationLag,gridPos={'x':6,'y':0,'w':12,'h':10})
.addPanel(usefulLinks,gridPos={'x':18,'y':0,'w':6,'h':7})
.addPanel(clusterRight,gridPos={'x':18,'y':7,'w':6,'h':3})
.addPanel(
    row.new(title="Physical lags", collapse=true)
    .addPanel(replicationLagSourceSeconds,gridPos={'x':0,'y':11,'w':12,'h':10})
    .addPanel(replicationLagTargetSeconds,gridPos={'x':12,'y':11,'w':12,'h':10})
    .addPanel(replicationLagSourceBytes,gridPos={'x':0,'y':21,'w':12,'h':10})
    .addPanel(replicationLagTargetBytes,gridPos={'x':12,'y':21,'w':12,'h':10}),
    gridPos={
        x: 0,
        y: 11,
        w: 24,
        h: 1,
    }
)
.addPanel(
    row.new(title="TPS (commits)", collapse=true)
    .addPanel(sourceLeaderTPSCommits,gridPos={'x':0,'y':12,'w':12,'h':8})
    .addPanel(targetLeaderTPSCommits,gridPos={'x':12,'y':12,'w':12,'h':8})
    .addPanel(sourceStandbysTPSCommits,gridPos={'x':0,'y':20,'w':12,'h':8})
    .addPanel(targetStandbysTPSCommits,gridPos={'x':12,'y':20,'w':12,'h':8}),
    gridPos={
        x: 0,
        y: 12,
        w: 24,
        h: 1,
    }
)
.addPanel(
    row.new(title="TPS rollbacks – ERROR RATES", collapse=true)
    .addPanel(sourceLeaderRollbackTPSErrors,gridPos={'x':0,'y':13,'w':12,'h':8})
    .addPanel(targetLeaderRollbackTPSErrors,gridPos={'x':12,'y':13,'w':12,'h':8})
    .addPanel(sourceStandbysRollbackTPSErrors,gridPos={'x':0,'y':21,'w':12,'h':8})
    .addPanel(targetStandbysRollbackTPSErrors,gridPos={'x':12,'y':21,'w':12,'h':8}),
    gridPos={
        x: 0,
        y: 13,
        w: 24,
        h: 1,
    }
)
.addPanel(
    row.new(title="Tuple stats: ins/upd/del, index fetches, seq reads", collapse=true)
    .addPanel(sourceWritesTuple,gridPos={'x':0,'y':14,'w':12,'h':8})
    .addPanel(targetWritesTuple,gridPos={'x':12,'y':14,'w':12,'h':8})
    .addPanel(sourceIndexTupleFetches,gridPos={'x':0,'y':22,'w':12,'h':8})
    .addPanel(targetIndexTupleFetches,gridPos={'x':12,'y':22,'w':12,'h':8})
    .addPanel(sourceSeqTupleReads,gridPos={'x':0,'y':30,'w':12,'h':8})
    .addPanel(targetSeqTupleReads,gridPos={'x':12,'y':30,'w':12,'h':8}),
    gridPos={
        x: 0,
        y: 14,
        w: 24,
        h: 1,
    }
)
