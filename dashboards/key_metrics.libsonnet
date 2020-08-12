local basic = import 'grafana/basic.libsonnet';
local colors = import 'grafana/colors.libsonnet';
local commonAnnotations = import 'grafana/common_annotations.libsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local sliPromQL = import 'sli_promql.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;
local selectors = import 'promql/selectors.libsonnet';
local statusDescription = import 'status_description.libsonnet';

local defaultEnvironmentSelector = { environment: '$environment' };

local generalGraphPanel(
  title,
  description=null,
  linewidth=2,
  sort='increasing',
  legend_show=true,
  stableId=null
      ) =
  basic.graphPanel(
    title,
    linewidth=linewidth,
    description=description,
    sort=sort,
    legend_show=legend_show,
    stableId=stableId,
  )
  .addSeriesOverride(seriesOverrides.lastWeek)
  .addSeriesOverride(seriesOverrides.degradationSlo)
  .addSeriesOverride(seriesOverrides.outageSlo)
  .addSeriesOverride(seriesOverrides.slo);

local generalApdexPanel(
  title,
  serviceType,
  serviceStage,
  environmentSelectorHash=defaultEnvironmentSelector,
  compact=false,
  description='',
  stableId=null,
  query=null,
  legendFormat=null,
  sort='increasing',
  linewidth=null,
  legend_show=null,
) =
    generalGraphPanel(
      title,
      description=description,
      sort=sort,
      linewidth=if linewidth == null then if compact then 1 else 2 else linewidth,
      legend_show=if legend_show == null then if compact then false else true else legend_show,
      stableId=stableId,
    )
    .addTarget(
      promQuery.target(
        query,
        legendFormat=legendFormat,
      )
    )
    .addTarget(  // 6h apdex SLO threshold
      promQuery.target(
        sliPromQL.apdex.serviceApdexDegradationSLOQuery(environmentSelectorHash, serviceType, serviceStage),
        interval='5m',
        legendFormat='6h Degradation SLO',
      ),
    )
    .addTarget(  // 1h apdex SLO threshold
      promQuery.target(
        sliPromQL.apdex.serviceApdexOutageSLOQuery(environmentSelectorHash, serviceType, serviceStage),
        interval='5m',
        legendFormat='1h Outage SLO',
      ),
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label=if compact then '' else 'Apdex %',
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    );

local generalErrorRatePanel(
  title,
  serviceType,
  serviceStage,
  environmentSelectorHash=defaultEnvironmentSelector,
  compact=false,
  description='Error rates are a measure of unhandled service exceptions within a minute period. Client errors are excluded when possible. Lower is better',
  stableId=null,
  query=null,
  legendFormat=null,
  sort='decreasing',
  linewidth=null,
  legend_show=null,
) =
    generalGraphPanel(
      title,
      description=description,
      sort=sort,
      linewidth=if linewidth == null then if compact then 1 else 2 else linewidth,
      legend_show=if legend_show == null then if compact then false else true else legend_show,
      stableId=stableId,
    )
    .addTarget(
      promQuery.target(
        query,
        legendFormat=legendFormat,
      )
    )
    .addTarget(  // 6h error rate SLO for gitlab_service_errors:ratio metric
      promQuery.target(
        sliPromQL.errorRate.serviceErrorRateDegradationSLOQuery(environmentSelectorHash, serviceType, serviceStage),
        interval='5m',
        legendFormat='6h Degradation SLO',
      ),
    )
    .addTarget(  // 1h error rate SLO for gitlab_service_errors:ratio metric
      promQuery.target(
        sliPromQL.errorRate.serviceErrorRateOutageSLOQuery(environmentSelectorHash, serviceType, serviceStage),
        interval='5m',
        legendFormat='1h Outage SLO',
      ),
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      min=0,
      label=if compact then '' else '% Requests in Error',
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    );

local generalQPSPanel(
  title,
  serviceType,
  serviceStage,
  environmentSelectorHash=defaultEnvironmentSelector,
  compact=false,
  description='The operation rate is the sum total of all requests being handle for all components within this service. Note that a single user request can lead to requests to multiple components. Higher is busier.',
  stableId=null,
  query=null,
  legendFormat=null,
  sort='decreasing',
  linewidth=null,
  legend_show=null,
) =
    generalGraphPanel(
      'RPS - Service Requests per Second',
      sort=sort,
      legend_show=!compact,
      linewidth=if compact then 1 else 2,
      stableId=stableId,
    )
    .addTarget(  // Primary metric
      promQuery.target(
        query,
        legendFormat=legendFormat,
      )
    )
    .addSeriesOverride(seriesOverrides.upper)
    .addSeriesOverride(seriesOverrides.lower);

{
  apdexPanel(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
    compact=false,
    description='Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.',
    stableId=null,
  )::
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };

    generalApdexPanel(
      'Latency: Apdex',
      serviceType,
      serviceStage,
      environmentSelectorHash=environmentSelectorHash,
      compact=compact,
      description=description,
      stableId=stableId,
      query=sliPromQL.apdex.serviceApdexQuery(selectorHash, '$__interval', worstCase=true),
      legendFormat='{{ type }} service',
    )
    .addTarget(  // Primary metric (avg case)
      promQuery.target(
        sliPromQL.apdex.serviceApdexQuery(selectorHash, '$__interval', worstCase=false),
        legendFormat='{{ type }} service (avg)',
      )
    )
    .addTarget(  // Last week
      promQuery.target(
        sliPromQL.apdex.serviceApdexQueryWithOffset(selectorHash, '1w'),
        legendFormat='last week',
      )
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/ service$/'))
    .addSeriesOverride(seriesOverrides.averageCaseSeries('/ service \\(avg\\)$/', { fillBelowTo: serviceType + ' service' }))
    .addDataLink({
      url: '/d/alerts-service_multiburn_apdex?${__url_time_range}&${__all_variables}&var-type=%(type)s' % { type: serviceType },
      title: 'Service Apdex Multi-Burn Analysis',
      targetBlank: true,
    }),

  singleComponentApdexPanel(
    serviceType,
    serviceStage,
    component,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
      component: component,
    };
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage, component: component };

    generalApdexPanel(
      '%(component)s Apdex' % formatConfig,
      serviceType,
      serviceStage,
      environmentSelectorHash=environmentSelectorHash,
      query=sliPromQL.apdex.componentApdexQuery(selectorHash, '$__interval'),
      legendFormat='{{ component }} apdex',
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* apdex$/'))
    .addDataLink({
      url: '/d/alerts-component_multiburn_apdex?${__url_time_range}&${__all_variables}&var-type=%(type)s&var-component=%(component)s' % {
        type: serviceType,
        component: component,
      },
      title: 'Component Apdex Multi-Burn Analysis',
      targetBlank: true,
    }),

  singleComponentNodeApdexPanel(
    serviceType,
    serviceStage,
    component,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
      component: component,
    };
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage, component: component };

    generalApdexPanel(
      '🖥 Per-Node %(component)s Apdex' % formatConfig,
      serviceType,
      serviceStage,
      environmentSelectorHash=environmentSelectorHash,
      query=sliPromQL.apdex.componentNodeApdexQuery(selectorHash, '$__interval'),
      legendFormat='{{ fqdn }} {{ component }} apdex',
      linewidth=1,
      legend_show=false,
    )
    .addDataLink({
      url: '/d/alerts-component_node_multiburn_apdex?${__url_time_range}&${__all_variables}&var-type=%(type)s&var-fqdn=${__series.labels.fqdn}' % { type: serviceType },
      title: 'Component/Node Apdex Multi-Burn Analysis',
      targetBlank: true,
    }),

  componentApdexPanel(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
    };
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };

    generalApdexPanel(
      'Component Latency: Apdex',
      serviceType,
      serviceStage,
      environmentSelectorHash=environmentSelectorHash,
      query=sliPromQL.apdex.componentApdexQuery(selectorHash, '$__interval'),
      legendFormat='{{ component }} component',
    ),

  errorRatesPanel(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
    compact=false,
    includeLastWeek=true,
    stableId=null,
  )::
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };

    generalErrorRatePanel(
      'Error Ratios',
      serviceType=serviceType,
      serviceStage=serviceStage,
      environmentSelectorHash=environmentSelectorHash,
      compact=compact,
      stableId=stableId,
      query=sliPromQL.errorRate.serviceErrorRateQuery(selectorHash, '$__interval', worstCase=true),
      legendFormat='{{ type }} service',
    )
    .addTarget(  // Last week
      promQuery.target(
        sliPromQL.errorRate.serviceErrorRateQueryWithOffset(selectorHash, '1w'),
        legendFormat='last week',
      ) + {
        [if !includeLastWeek then 'hide']: true,
      }
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/ service$/', { fillBelowTo: serviceType + ' service (avg)' }))
    .addSeriesOverride(seriesOverrides.averageCaseSeries('/ service \\(avg\\)$/', { fillGradient: 10 }))
    .addDataLink({
      url: '/d/alerts-service_multiburn_error?${__url_time_range}&${__all_variables}&var-type=%(type)s' % { type: serviceType },
      title: 'Service Error-Rate Multi-Burn Analysis',
      targetBlank: true,
    }),

  singleComponentErrorRates(
    serviceType,
    serviceStage,
    componentName,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
      component: componentName,
    };
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage, component: componentName };

    generalErrorRatePanel(
      '%(component)s Component Error Rates' % formatConfig,
      serviceType=serviceType,
      serviceStage=serviceStage,
      environmentSelectorHash=environmentSelectorHash,
      query=sliPromQL.errorRate.componentErrorRateQuery(selectorHash),
      legendFormat='{{ component }} error rate',
      linewidth=1,
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* error rate$/'))
    .addDataLink({
      url: '/d/alerts-component_multiburn_error?${__url_time_range}&${__all_variables}&var-type=%(type)s&var-component=%(component)s' % {
        type: serviceType,
        component: componentName,
      },
      title: 'Component Error-Rate Multi-Burn Analysis',
      targetBlank: true,
    }),

  singleComponentNodeErrorRates(
    serviceType,
    serviceStage,
    componentName,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
      component: componentName,
    };
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage, component: componentName };

    generalErrorRatePanel(
      '🖥 Per-Node %(component)s Component Error Rates' % formatConfig,
      serviceType=serviceType,
      serviceStage=serviceStage,
      environmentSelectorHash=environmentSelectorHash,
      query=sliPromQL.errorRate.componentNodeErrorRateQuery(selectorHash),
      legendFormat='{{ fqdn }} {{ component }} error rate',
      legend_show=false,
    )
    .addDataLink({
      url: '/d/alerts-component_node_multiburn_error?${__url_time_range}&${__all_variables}&var-type=%(type)s&var-fqdn=${__series.labels.fqdn}' % { type: serviceType },
      title: 'Component/Node Error Multi-Burn Analysis',
      targetBlank: true,
    }),

  componentErrorRates(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };

    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
      selector: selectors.serializeHash(environmentSelectorHash { type: serviceType, stage: serviceStage }),
    };

    generalErrorRatePanel(
      'Component Error Rates',
      serviceType=serviceType,
      serviceStage=serviceStage,
      environmentSelectorHash=environmentSelectorHash,
      query=sliPromQL.errorRate.componentErrorRateQuery(selectorHash),
      legendFormat='{{ component }} component',
    ),

  qpsPanel(
    serviceType,
    serviceStage,
    compact=false,
    environmentSelectorHash=defaultEnvironmentSelector,
    stableId=null,
  )::
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };

    generalQPSPanel(
      'RPS - Service Requests per Second',
      serviceType,
      serviceStage,
      environmentSelectorHash=defaultEnvironmentSelector,
      compact=compact,
      stableId=stableId,
      query=sliPromQL.opsRate.serviceOpsRateQuery(selectorHash, '$__interval'),
      legendFormat='{{ type }} service',
    )
    .addTarget(  // Last week
      promQuery.target(
        sliPromQL.opsRate.serviceOpsRateQueryWithOffset(selectorHash, '1w'),
        legendFormat='last week',
      )
    )
    .addTarget(
      promQuery.target(
        sliPromQL.opsRate.serviceOpsRatePrediction(selectorHash, 2),
        legendFormat='upper normal',
      ),
    )
    .addTarget(
      promQuery.target(
        sliPromQL.opsRate.serviceOpsRatePrediction(selectorHash, -2),
        legendFormat='lower normal',
      ),
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/ service$/')),

  singleComponentQPSPanel(
    serviceType,
    serviceStage,
    componentName,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
      component: componentName,
    };
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage, component: componentName };

    generalQPSPanel(
      '%(component)s Component RPS - Requests per Second' % formatConfig,
      serviceType,
      serviceStage,
      environmentSelectorHash=defaultEnvironmentSelector,
      query=sliPromQL.opsRate.componentOpsRateQuery(selectorHash, '$__interval'),
      legendFormat='{{ component }} RPS',
      linewidth=1
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* RPS$/')),

  singleComponentNodeQPSPanel(
    serviceType,
    serviceStage,
    componentName,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
      component: componentName,
    };
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage, component: componentName };

    generalQPSPanel(
      '🖥 Per-Node %(component)s Component RPS - Requests per Second' % formatConfig,
      serviceType,
      serviceStage,
      environmentSelectorHash=defaultEnvironmentSelector,
      legend_show=false,
      query=sliPromQL.opsRate.componentNodeOpsRateQuery(selectorHash, '$__interval'),
      legendFormat='{{ fqdn }} {{ component }} RPS',
      linewidth=1
    ),

  componentQpsPanel(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
    };
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };

    generalQPSPanel(
      'Component RPS - Requests per Second',
      serviceType,
      serviceStage,
      environmentSelectorHash=defaultEnvironmentSelector,
      legend_show=false,
      query=sliPromQL.opsRate.componentOpsRateQuery(selectorHash, '$__interval'),
      legendFormat='{{ component }} component',
    ),

  saturationPanel(
    serviceType,
    serviceStage,
    compact=false,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    self.componentSaturationPanel(serviceType, serviceStage, compact, environmentSelectorHash=environmentSelectorHash),

  componentSaturationPanel(
    serviceType,
    serviceStage,
    compact=false,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::

    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };
    local formatConfig = {
      serviceType: serviceType,
      serviceStage: serviceStage,
      selector: selectors.serializeHash(selectorHash),
    };
    generalGraphPanel(
      'Saturation',
      description='Saturation is a measure of what ratio of a finite resource is currently being utilized. Lower is better.',
      sort='decreasing',
      legend_show=!compact,
      linewidth=if compact then 1 else 2,
    )
    .addTarget(  // Primary metric
      promQuery.target(
        |||
          max(
            max_over_time(
              gitlab_component_saturation:ratio{%(selector)s}[$__interval]
            )
          ) by (component)
        ||| % formatConfig,
        legendFormat='{{ component }} component',
      )
    )
    .resetYaxes()
    .addYaxis(
      format='percentunit',
      max=1,
      label=if compact then '' else 'Saturation %',
    )
    .addYaxis(
      format='short',
      max=1,
      min=0,
      show=false,
    ),

  headlineMetricsRow(
    serviceType,
    serviceStage,
    startRow,
    rowTitle='🌡️ Service Level Indicators (𝙎𝙇𝙄𝙨)',
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    layout.grid([
      row.new(title=rowTitle, collapse=false),
    ], cols=1, rowHeight=1, startRow=startRow)
    +
    layout.splitColumnGrid([
      [
        self.apdexPanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash),
        statusDescription.serviceApdexStatusDescriptionPanel(environmentSelectorHash { type: serviceType, stage: serviceStage }),
      ],
      [
        self.errorRatesPanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash),
        statusDescription.serviceErrorStatusDescriptionPanel(environmentSelectorHash { type: serviceType, stage: serviceStage }),
      ],
      [
        self.qpsPanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash),
      ],
      [
        self.saturationPanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash),
      ],
    ], [4, 1], startRow=startRow + 1),

  keyServiceMetricsRow(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    row.new(title='🏅 Key Service Metrics', collapse=true)
    .addPanels(layout.grid([
      self.apdexPanel(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
      self.errorRatesPanel(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
      self.qpsPanel(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
      self.saturationPanel(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
    ])),

  keyComponentMetricsRow(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    row.new(title='🔩 Service Component Metrics', collapse=true)
    .addPanels(layout.grid([
      self.componentApdexPanel(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
      self.componentErrorRates(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
      self.componentQpsPanel(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
      self.componentSaturationPanel(serviceType, serviceStage, environmentSelectorHash=environmentSelectorHash),
    ])),
}
