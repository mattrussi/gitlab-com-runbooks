local basic = import 'grafana/basic.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';

local barPanel(title, legendFormat, format, query ) =
    basic.timeseries(
        title=title,
        legendFormat=legendFormat,
        format=format,
        query=query,
        fill=1
  ) + {
    lines: false,
    bars: true,
  };

local pendingOperations(selector) =
  barPanel(
    title='Operations pending replication',
    legendFormat='Pending operations',
    format='short',
    query=|||
        avg_over_time(aws_s3_operations_pending_replication_sum{%(selector)s}[10m])
    ||| % { selector: selector }
  );

local latency(selector) =
  basic.timeseries(
    title='Replication latency',
    legendFormat='Latency',
    format='short',
    query=|||
        avg_over_time(aws_s3_replication_latency_maximum{%(selector)s}[10m])
    ||| % { selector: selector }
  );


local bytesPending(selector) =
  barPanel(
    title='Bytes pending replication',
    legendFormat='Bytes pending',
    format='bytes',
    query=|||
        avg_over_time(aws_s3_bytes_pending_replication_maximum{%(selector)s}[10m])
    ||| % { selector: selector }
  );

local operationsFailed(selector) =
  basic.timeseries(
    title='Operations failed replication',
    legendFormat='Failed replication',
    format='short',
    query=|||
        avg_over_time(aws_s3_operations_failed_replication_sum{%(selector)s}[10m])
    ||| % { selector: selector }
  );

{
    pendingOperations:: pendingOperations,
    latency:: latency,
    bytesPending:: bytesPending,
    operationsFailed:: operationsFailed
}
