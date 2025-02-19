local basic = import 'grafana/basic.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';

local emitRecords(selector) =
  basic.timeseries(
    title='Current emit records',
    legendFormat='{{shard}} - {{plugin}}',
    linewidth=2,
    format='short',
    fill=0,
    min=0,
    query=|||
      sum by (shard, plugin) (
        rate(fluentd_output_status_emit_records{%(selector)s}[1m])
      )
    ||| % { selector: selector }
  );

local retryWait(selector) =
  basic.timeseries(
    title='Current retry wait',
    legendFormat='{{shard}} - {{plugin}}',
    linewidth=2,
    format='short',
    fill=0,
    min=0,
    query=|||
      sum by (shard, plugin) (
        rate(fluentd_output_status_retry_wait{%(selector)s}[1m])
      )
    ||| % { selector: selector }
  );

local writeCounts(selector) =
  basic.timeseries(
    title='Current write counts',
    legendFormat='{{shard}} - {{plugin}}',
    linewidth=2,
    format='short',
    fill=0,
    min=0,
    query=|||
      sum by (shard, plugin) (
        rate(fluentd_output_status_write_count{%(selector)s}[1m])
      )
    ||| % { selector: selector }
  );

local errorAndRetryRate(selector) =
  basic.timeseries(
    title='Fluentd output error/retry rate',
    legendFormat='{{shard}} - {{plugin}} - Retry rate',
    linewidth=2,
    format='ops',
    fill=0,
    min=0,
    query=|||
      sum by (shard, plugin) (
        rate(fluentd_output_status_retry_count{%(selector)s}[1m])
      )
    ||| % { selector: selector }
  ).addTarget(
    promQuery.target(
      expr=|||
        sum by (shard, plugin) (
            rate(fluentd_output_status_num_errors{%(selector)s}[1m])
        )
      ||| % { selector: selector },
      legendFormat='{{shard}} - {{plugin}} - Error rate',
    )
  );

local outputFlushTime(selector) =
  basic.timeseries(
    title='Fluentd output status flush time rate',
    legendFormat='{{shard}} - {{plugin}} - Time',
    linewidth=2,
    format='ms',
    fill=0,
    min=0,
    query=|||
      sum by (shard, plugin) (
        rate(fluentd_output_status_flush_time_count{%(selector)s}[1m])
      )
    ||| % { selector: selector }
  );

local bufferLength(selector) =
  basic.timeseries(
    title='Maximum buffer length in last 5min',
    legendFormat='{{shard}} - {{plugin}} - Count',
    linewidth=2,
    format='short',
    fill=0,
    min=0,
    query=|||
      sum by (shard, plugin) (
        max_over_time(fluentd_output_status_buffer_queue_length{%(selector)s}[5m])
      )
    ||| % { selector: selector }
  );

local bufferTotalSize(selector) =
  basic.timeseries(
    title='Total size of queue buffers',
    legendFormat='{{shard}} - {{plugin}}',
    linewidth=2,
    format='bytes',
    fill=0,
    min=0,
    query=|||
      sum by (shard, plugin) (
        fluentd_output_status_buffer_total_bytes{%(selector)s}
      )
    ||| % { selector: selector }
  );

local bufferFreeSpace(selector) =
  basic.timeseries(
    title='Buffer available space ratio',
    legendFormat='{{shard}} - {{plugin}}',
    linewidth=2,
    format='percent',
    fill=1,
    min=0,
    query=|||
      min by(plugin, shard) (
        fluentd_output_status_buffer_available_space_ratio{%(selector)s}
      )
    ||| % { selector: selector }
  );

{
    emitRecords:: emitRecords,
    retryWait:: retryWait,
    writeCounts:: writeCounts,
    errorAndRetryRate:: errorAndRetryRate,
    outputFlushTime:: outputFlushTime,
    bufferLength:: bufferLength,
    bufferTotalSize:: bufferTotalSize,
    bufferFreeSpace:: bufferFreeSpace
}