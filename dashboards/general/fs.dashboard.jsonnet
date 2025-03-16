local panels = import 'gitlab-dashboards/panels.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local panel = import 'grafana/time-series/panel.libsonnet';
local target = import 'grafana/time-series/target.libsonnet';

local useTimeSeriesPlugin = true;

local generalBytesGraphPanel(title, description=null) =
  panel.basic(
    title,
    description=description,
    unit='bytes'
  )
  .addYaxis(
    label='Size',
  );

//######################################
// ARC                                 #
//######################################

local arcHitRatePanel =
  if useTimeSeriesPlugin then
    panel.percentageTimeSeries('ZFS ARC Hit Rate')
    .addTarget(
      target.prometheus(
        |||
          node_zfs_arc_hits{env="$environment", type="$type"}
          /
          (node_zfs_arc_hits{env="$environment", type="$type"} + node_zfs_arc_misses{env="$environment", type="$type"})
        |||,
        legendFormat='{{instance}}'
      )
    )
  else
    panels.generalPercentageGraphPanel('ZFS ARC Hit Rate')
    .addTarget(
      promQuery.target(
        |||
          node_zfs_arc_hits{env="$environment", type="$type"}
          /
          (node_zfs_arc_hits{env="$environment", type="$type"} + node_zfs_arc_misses{env="$environment", type="$type"})
        |||,
        legendFormat='{{instance}}'
      )
    );

local arcDemandHitRatePanel =
  if useTimeSeriesPlugin then
    panel.percentageTimeSeries('ZFS ARC Demand Hit Rate')
    .addTarget(
      target.prometheus(
        |||
          (node_zfs_arc_demand_data_hits{env="$environment", type="$type"} + node_zfs_arc_demand_metadata_hits{env="$environment", type="$type"})
          /
          (
            node_zfs_arc_demand_data_hits{env="$environment", type="$type"} + node_zfs_arc_demand_metadata_hits{env="$environment", type="$type"}
            + node_zfs_arc_demand_data_misses{env="$environment", type="$type"} + node_zfs_arc_demand_metadata_misses{env="$environment", type="$type"}
          )
        |||,
        legendFormat='{{instance}}'
      )
    )
  else
    panels.generalPercentageGraphPanel('ZFS ARC Demand Hit Rate')
    .addTarget(
      promQuery.target(
        |||
          (node_zfs_arc_demand_data_hits{env="$environment", type="$type"} + node_zfs_arc_demand_metadata_hits{env="$environment", type="$type"})
          /
          (
            node_zfs_arc_demand_data_hits{env="$environment", type="$type"} + node_zfs_arc_demand_metadata_hits{env="$environment", type="$type"}
            + node_zfs_arc_demand_data_misses{env="$environment", type="$type"} + node_zfs_arc_demand_metadata_misses{env="$environment", type="$type"}
          )
        |||,
        legendFormat='{{instance}}'
      )
    );

//######################################
// Utilization                         #
//######################################

local fsUtilizationPanel =
  if useTimeSeriesPlugin then
    generalBytesGraphPanel('Filesystem Utilization')
    .addTarget(
      target.prometheus(
        |||
          min by (device) (node_filesystem_size_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"})
        |||,
        legendFormat='Limit ({{device}})'
      )
    )
    .addTarget(
      target.prometheus(
        |||
          node_filesystem_size_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"}
          -
          node_filesystem_free_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"}
        |||,
        legendFormat='{{instance}} {{device}}'
      )
    )
  else
    panels.generalBytesGraphPanel('Filesystem Utilization')
    .addTarget(
      promQuery.target(
        |||
          min by (device) (node_filesystem_size_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"})
        |||,
        legendFormat='Limit ({{device}})'
      )
    )
    .addTarget(
      promQuery.target(
        |||
          node_filesystem_size_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"}
          -
          node_filesystem_free_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"}
        |||,
        legendFormat='{{instance}} {{device}}'
      )
    );

local totalFsUtilizationPanel =
  if useTimeSeriesPlugin then
    generalBytesGraphPanel('Total Filesystem Utilization')
    .addTarget(
      target.prometheus(
        |||
          sum by (device) (node_filesystem_size_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"})
        |||,
        legendFormat='Limit ({{device}})'
      )
    )
    .addTarget(
      target.prometheus(
        |||
          sum by (device)
          (
            node_filesystem_size_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"}
            -
            node_filesystem_free_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"}
          )
        |||,
        legendFormat='All Instances ({{device}})'
      )
    )
  else
    panels.generalBytesGraphPanel('Total Filesystem Utilization')
    .addTarget(
      promQuery.target(
        |||
          sum by (device) (node_filesystem_size_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"})
        |||,
        legendFormat='Limit ({{device}})'
      )
    )
    .addTarget(
      promQuery.target(
        |||
          sum by (device)
          (
            node_filesystem_size_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"}
            -
            node_filesystem_free_bytes{device=~"/dev/.+", env="$environment", type="$type", mountpoint!="/", mountpoint!="/var/log"}
          )
        |||,
        legendFormat='All Instances ({{device}})'
      )
    );

// As tank/dataset grows, the reported sizes of all other filesystems in the
// zpool (tank/reservation, and the top-level "tank") decrease, to take account
// of decreasing availability. To properly report the absolute capacity limit of
// the zpool, we must add the space occupied by the dataset to the reported size
// of the only filesystem containing a reservation.
// The limit lines are not flat, because the capacity of ZFS filesystems
// decreases as metadata is dynamically provisioned and destroyed.
// Therefore the available capacity will differ from node to node, even for
// equally sized disks.
// Because we use the "min" aggregator, the reported limits are worst-case, and
// are equal to the lowest limit of all nodes in the env/type fleet.
local zfsFsUtilizationPanel =
  if useTimeSeriesPlugin then
    generalBytesGraphPanel('Filesystem Utilization (ZFS)')
    .addTarget(
      target.prometheus(
        |||
          min
          (
            node_filesystem_size_bytes{device="tank/reservation", env="$environment", type="$type"}
            + ignoring (device, mountpoint)
            (
              node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"}
              -
              node_filesystem_free_bytes{device="tank/dataset", env="$environment", type="$type"}
            )
          )
        |||,
        legendFormat='Absolute Limit'
      )
    )
    .addTarget(
      target.prometheus(
        |||
          min (node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"})
        |||,
        legendFormat='Limit excluding reservation'
      )
    )
    .addTarget(
      target.prometheus(
        |||
          node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"}
          -
          node_filesystem_free_bytes{device="tank/dataset", env="$environment", type="$type"}
        |||,
        legendFormat='{{instance}}'
      )
    )
  else
    panels.generalBytesGraphPanel('Filesystem Utilization (ZFS)')
    .addTarget(
      promQuery.target(
        |||
          min
          (
            node_filesystem_size_bytes{device="tank/reservation", env="$environment", type="$type"}
            + ignoring (device, mountpoint)
            (
              node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"}
              -
              node_filesystem_free_bytes{device="tank/dataset", env="$environment", type="$type"}
            )
          )
        |||,
        legendFormat='Absolute Limit'
      )
    )
    .addTarget(
      promQuery.target(
        |||
          min (node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"})
        |||,
        legendFormat='Limit excluding reservation'
      )
    )
    .addTarget(
      promQuery.target(
        |||
          node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"}
          -
          node_filesystem_free_bytes{device="tank/dataset", env="$environment", type="$type"}
        |||,
        legendFormat='{{instance}}'
      )
    );

// As tank/dataset grows, the reported sizes of all other filesystems in the
// zpool (tank/reservation, and the top-level "tank") decrease, to take account
// of decreasing availability. To properly report the absolute capacity limit of
// the zpool, we must add the space occupied by the dataset to the reported size
// of the only filesystem containing a reservation.
// The limit lines are not flat, because the capacity of ZFS filesystems
// decreases as metadata is dynamically provisioned and destroyed.
// Therefore the available capacity will differ from node to node, even for
// equally sized disks.
local totalZfsFsUtilizationPanel =
  if useTimeSeriesPlugin then
    generalBytesGraphPanel('Total Filesystem Utilization (ZFS)')
    .addTarget(
      target.prometheus(
        |||
          sum
          (
            node_filesystem_size_bytes{device="tank/reservation", env="$environment", type="$type"}
            + ignoring (device, mountpoint)
            (
              node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"}
              -
              node_filesystem_free_bytes{device="tank/dataset", env="$environment", type="$type"}
            )
          )
        |||,
        legendFormat='Absolute Limit'
      )
    )
    .addTarget(
      target.prometheus(
        |||
          sum (node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"})
        |||,
        legendFormat='Limit excluding reservation'
      )
    )
    .addTarget(
      target.prometheus(
        |||
          sum
          (
            node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"}
            -
            node_filesystem_free_bytes{device="tank/dataset", env="$environment", type="$type"}
          )
        |||,
        legendFormat='All Instances'
      )
    )
  else
    panels.generalBytesGraphPanel('Total Filesystem Utilization (ZFS)')
    .addTarget(
      promQuery.target(
        |||
          sum
          (
            node_filesystem_size_bytes{device="tank/reservation", env="$environment", type="$type"}
            + ignoring (device, mountpoint)
            (
              node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"}
              -
              node_filesystem_free_bytes{device="tank/dataset", env="$environment", type="$type"}
            )
          )
        |||,
        legendFormat='Absolute Limit'
      )
    )
    .addTarget(
      promQuery.target(
        |||
          sum (node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"})
        |||,
        legendFormat='Limit excluding reservation'
      )
    )
    .addTarget(
      promQuery.target(
        |||
          sum
          (
            node_filesystem_size_bytes{device="tank/dataset", env="$environment", type="$type"}
            -
            node_filesystem_free_bytes{device="tank/dataset", env="$environment", type="$type"}
          )
        |||,
        legendFormat='All Instances'
      )
    );


basic.dashboard(
  'Filesystems',
  tags=['general'],
)
.addTemplate(templates.type)
.addPanels(layout.grid([
  fsUtilizationPanel,
  totalFsUtilizationPanel,
  zfsFsUtilizationPanel,
  totalZfsFsUtilizationPanel,
  arcHitRatePanel,
  arcDemandHitRatePanel,
], cols=2, rowHeight=10))
