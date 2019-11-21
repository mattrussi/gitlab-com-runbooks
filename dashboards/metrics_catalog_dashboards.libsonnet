local basic = import 'basic.libsonnet';
local grafana = import 'grafonnet/grafana.libsonnet';
local layout = import 'layout.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';
local thresholds = import 'thresholds.libsonnet';
local row = grafana.row;

{
  componentLatencyPanel(
    title=null,
    serviceType,
    componentName,
    selector,
    aggregationLabels='',
    logBase=10,
    legendFormat='%(percentile_humanized)s %(componentName)s',
    min=0.01,
    intervalFactor=2,
  )::
    local service = metricsCatalog.getService(serviceType);
    local component = service.components[componentName];
    local percentile = service.slos.apdexRatio;

    basic.latencyTimeseries(
      title=if title == null then 'Estimated latency for ' + componentName else title,
      query=component.apdex.percentileLatencyQuery(
        percentile=percentile,
        aggregationLabels=aggregationLabels,
        selector=selector,
        rangeInterval='$__interval',
      ),
      logBase=logBase,
      legendFormat=legendFormat % { percentile_humanized: 'p' + (percentile * 100), componentName: componentName },
      min=min,
      intervalFactor=intervalFactor,
    ) + {
      thresholds: [
        thresholds.errorLevel('gt', component.apdex.toleratedThreshold),
        thresholds.warningLevel('gt', component.apdex.satisfiedThreshold),
      ],
    },

  componentRPSPanel(
    title=null,
    serviceType,
    componentName,
    selector,
    aggregationLabels='',
    legendFormat='%(componentName)s errors',
    intervalFactor=2,
  )::
    local service = metricsCatalog.getService(serviceType);
    local component = service.components[componentName];

    basic.timeseries(
      title=if title == null then 'RPS for ' + componentName else title,
      query=component.requestRate.rateQuery(
        aggregationLabels=aggregationLabels,
        selector=selector,
        rangeInterval='$__interval',
      ),
      legendFormat=legendFormat % { componentName: componentName },
      intervalFactor=intervalFactor,
      yAxisLabel='Requests per Second'
    ),


  componentErrorsPanel(
    title=null,
    serviceType,
    componentName,
    selector,
    aggregationLabels='',
    legendFormat='%(componentName)s errors',
    intervalFactor=2,
  )::
    local service = metricsCatalog.getService(serviceType);
    local component = service.components[componentName];

    basic.timeseries(
      title=if title == null then 'Errors for ' + componentName else title,
      query=component.errorRate.changesQuery(
        aggregationLabels=aggregationLabels,
        selector=selector,
        rangeInterval='$__interval',
      ),
      legendFormat=legendFormat % { componentName: componentName },
      intervalFactor=intervalFactor,
      yAxisLabel='Errors'
    ),

  componentDetailMatrix(serviceType, componentName, selector, aggregationSets)::
    row.new(title='🔬 %(componentName)s Component Detail' % { componentName: componentName }, collapse=true)
    .addPanels(layout.grid(
      std.flattenArrays(
        std.map(function(aggregationSet)
          [
            self.componentLatencyPanel(
              title='Estimated ' + componentName + ' Latency - ' + aggregationSet.title,
              serviceType=serviceType,
              componentName=componentName,
              selector=selector,
              legendFormat='%(percentile_humanized)s ' + aggregationSet.legendFormat,
              aggregationLabels=aggregationSet.aggregationLabels
            ),

            self.componentRPSPanel(
              title=componentName + ' RPS - ' + aggregationSet.title,
              serviceType=serviceType,
              componentName=componentName,
              selector=selector,
              legendFormat=aggregationSet.legendFormat,
              aggregationLabels=aggregationSet.aggregationLabels
            ),

            self.componentErrorsPanel(
              title=componentName + ' Errors - ' + aggregationSet.title,
              serviceType=serviceType,
              componentName=componentName,
              legendFormat=aggregationSet.legendFormat,
              aggregationLabels=aggregationSet.aggregationLabels,
              selector=selector,
            ),
          ]
                , aggregationSets)
      ), cols=3
    )),


}
