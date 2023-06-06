local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local type = 'code_suggestions';
local formatConfig = {
  selector: selectors.serializeHash({ env: '$environment', environment: '$environment', type: type }),
};

basic.dashboard(
  'Triton',
  tags=['type:%s' % type, 'detail'],
  includeEnvironmentTemplate=true,
  includeStandardEnvironmentAnnotations=false,
)
.addPanels(
  layout.grid([
    basic.timeseries(
      stableId='request-success',
      title='Request Success / sec',
      query=|||
        sum by(model, version) (
          rate(nv_inference_request_success{%(selector)s}[$__rate_interval])
        )
      ||| % formatConfig,
      legendFormat='{{model}}-{{version}}',
      format='ops',
      yAxisLabel='Requests per Second',
      decimals=1,
    ),
    basic.timeseries(
      stableId='batchsize',
      title='Batchsize ( #infer/ #exec)',
      query=|||
        sum by(model, version) (
          rate(nv_inference_count{%(selector)s}[$__rate_interval])
        )
        /
        sum by(model, version) (
          rate(nv_inference_exec_count{%(selector)s}[$__rate_interval])
        )
      ||| % formatConfig,
      legendFormat='{{model}}-{{version}}',
      format='short',
      yAxisLabel='Average Batch Size',
      decimals=2,
      min=1,
    ),
    basic.timeseries(
      stableId='input-time-per-req',
      title='Input time / req',
      query=|||
        sum by(model, version) (
          rate(nv_inference_compute_input_duration_us{%(selector)s}[$__rate_interval])
        )
        /
        sum by(model, version) (
          rate(nv_inference_request_success{%(selector)s}[$__rate_interval])
        )
      ||| % formatConfig,
      legendFormat='{{model}}-{{version}}',
      format='µs',
      yAxisLabel='Average Input Duration',
      decimals=2,
    ),
    basic.timeseries(
      stableId='request-fail-sec',
      title='Request fail / sec',
      query=|||
        sum by(model, version) (
          rate(nv_inference_request_failure{%(selector)s}[$__rate_interval])
        )
      ||| % formatConfig,
      legendFormat='{{model}}-{{version}}',
      format='ops',
      yAxisLabel='Failures per Second',
      decimals=2,
    ),
    basic.timeseries(
      stableId='db_ratio',
      title='DB ratio ( #request / #exec )',
      query=|||
        sum by(model, version) (
          rate(nv_inference_request_success{%(selector)s}[$__rate_interval])
        )
        /
        sum by(model, version) (
          rate(nv_inference_exec_count{%(selector)s}[$__rate_interval])
        )
      ||| % formatConfig,
      legendFormat='{{model}}-{{version}}',
      format='short',
      yAxisLabel='Average Requests per Execution',
      decimals=2,
      min=1,
    ),
    basic.timeseries(
      stableId='queue_time',
      title='Queue time / req',
      query=|||
        sum(rate(nv_inference_queue_duration_us{%(selector)s}[$__rate_interval]))
        /
        sum(rate(nv_inference_request_success{%(selector)s}[$__rate_interval]))
      ||| % formatConfig,
      legendFormat='Latency',
      format='µs',
      yAxisLabel='Average Queue Time per Request',
      decimals=2,
    ),
    basic.timeseries(
      stableId='request_time',
      title='Request time',
      query=|||
        sum by(model, version) (
          rate(nv_inference_request_duration_us{%(selector)s}[$__rate_interval])
        )
        /
        sum by(model, version) (
          rate(nv_inference_request_success{%(selector)s}[$__rate_interval])
        )
      ||| % formatConfig,
      legendFormat='{{model}}-{{version}}',
      format='µs',
      yAxisLabel='Average Request Time per Request',
      decimals=2,
    ),
    basic.timeseries(
      stableId='output_time',
      title='Output time / req',
      query=|||
        sum by(model, version) (
          rate(nv_inference_compute_output_duration_us{%(selector)s}[$__rate_interval])
        )
        /
        sum by(model, version) (
          rate(nv_inference_request_success{%(selector)s}[$__rate_interval])
        )
      ||| % formatConfig,
      legendFormat='{{model}}-{{version}}',
      format='µs',
      yAxisLabel='Average Output Time per Request',
      decimals=2,
    ),
    basic.timeseries(
      stableId='inference_time',
      title='Inference time / req',
      query=|||
        sum by(model, version) (
          rate(nv_inference_compute_infer_duration_us{%(selector)s}[$__rate_interval])
        )
        /
        sum by(model, version) (
          rate(nv_inference_request_success{%(selector)s}[$__rate_interval])
        )
      ||| % formatConfig,
      legendFormat='{{model}}-{{version}}',
      format='µs',
      yAxisLabel='Average Inference Time per Request',
      decimals=2,
    ),
    basic.timeseries(
      stableId='gpu_utilization',
      title='Average GPU Utilization',
      query=|||
        avg(nv_gpu_utilization{%(selector)s})
      ||| % formatConfig,
      legendFormat='GPU Utilization %',
      format='percentunit',
      yAxisLabel='GPU Utilization %',
      decimals=2,
    ),
    basic.timeseries(
      stableId='gpu_power_usage',
      title='GPU Power Usage',
      query=|||
        sum(nv_gpu_power_usage{%(selector)s})
      ||| % formatConfig,
      legendFormat='Power',
      format='W',
      yAxisLabel='Watts',
      decimals=2,
    ),
  ], cols=3, rowHeight=10, startRow=0)
)
.trailer()
