local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local colors = import 'grafana/colors.libsonnet';
local commonAnnotations = import 'grafana/common_annotations.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local promQuery = import 'grafana/prom_query.libsonnet';
local seriesOverrides = import 'grafana/series_overrides.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local sliPromQL = import 'sli_promql.libsonnet';
local statusDescription = import 'status_description.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local annotation = grafana.annotation;

local defaultEnvironmentSelector = { environment: '$environment', env: '$environment' };

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
  .addSeriesOverride(seriesOverrides.upper)
  .addSeriesOverride(seriesOverrides.lower)
  .addSeriesOverride(seriesOverrides.lastWeek)
  .addSeriesOverride(seriesOverrides.degradationSlo)
  .addSeriesOverride(seriesOverrides.outageSlo)
  .addSeriesOverride(seriesOverrides.slo);

local genericApdexPanel(
  title,
  description='Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.',
  compact=false,
  stableId,
  primaryQueryExpr,
  legendFormat,
  linewidth=null,
  environmentSelectorHash,
  serviceType,
  sort='increasing',
  legend_show=null,
      ) =
  generalGraphPanel(
    title,
    description=description,
    sort=sort,
    legend_show=if legend_show == null then !compact else legend_show,
    linewidth=if linewidth == null then if compact then 1 else 2 else linewidth,
    stableId=stableId,
  )
  .addTarget(  // Primary metric (worst case)
    promQuery.target(
      primaryQueryExpr,
      legendFormat=legendFormat,
    )
  )
  .addTarget(  // Min apdex score SLO for gitlab_service_errors:ratio metric
    promQuery.target(
      sliPromQL.apdex.serviceApdexDegradationSLOQuery(environmentSelectorHash, serviceType),
      interval='5m',
      legendFormat='6h Degradation SLO (5% of monthly error budget)',
    ),
  )
  .addTarget(  // Double apdex SLO is Outage-level SLO
    promQuery.target(
      sliPromQL.apdex.serviceApdexOutageSLOQuery(environmentSelectorHash, serviceType),
      interval='5m',
      legendFormat='1h Outage SLO (2% of monthly error budget)',
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

local genericErrorPanel(
  title,
  description='Error rates are a measure of unhandled service exceptions per second. Client errors are excluded when possible. Lower is better',
  compact=false,
  stableId,
  primaryQueryExpr,
  legendFormat,
  linewidth=null,
  environmentSelectorHash,
  serviceType,
  sort='decreasing',
  legend_show=null,
      ) =
  generalGraphPanel(
    title,
    description=description,
    sort=sort,
    legend_show=if legend_show == null then !compact else legend_show,
    linewidth=if linewidth == null then if compact then 1 else 2 else linewidth,
    stableId=stableId,
  )
  .addTarget(
    promQuery.target(
      primaryQueryExpr,
      legendFormat=legendFormat,
    )
  )
  .addTarget(  // Maximum error rate SLO for gitlab_service_errors:ratio metric
    promQuery.target(
      sliPromQL.errorRate.serviceErrorRateDegradationSLOQuery(environmentSelectorHash, serviceType),
      interval='5m',
      legendFormat='6h Degradation SLO (5% of monthly error budget)',
    ),
  )
  .addTarget(  // Outage level SLO
    promQuery.target(
      sliPromQL.errorRate.serviceErrorRateOutageSLOQuery(environmentSelectorHash, serviceType),
      interval='5m',
      legendFormat='1h Outage SLO (2% of monthly error budget)',
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

local genericOperationRatePanel(
  title,
  description='The operation rate is the sum total of all requests being handle for all components within this service. Note that a single user request can lead to requests to multiple components. Higher is busier.',
  compact=false,
  stableId=null,
  primaryQueryExpr,
  legendFormat,
  linewidth=null,
  environmentSelectorHash,
  serviceType,
  sort='decreasing',
  legend_show=null,
      ) =
  generalGraphPanel(
    title,
    description=description,
    sort=sort,
    legend_show=if legend_show == null then !compact else legend_show,
    linewidth=if linewidth == null then if compact then 1 else 2 else linewidth,
    stableId=stableId,
  )
  .addTarget(  // Primary metric
    promQuery.target(
      primaryQueryExpr,
      legendFormat=legendFormat,
    )
  )
  .resetYaxes()
  .addYaxis(
    format='short',
    min=0,
    label=if compact then '' else 'Operations per Second',
  )
  .addYaxis(
    format='short',
    max=1,
    min=0,
    show=false,
  );

{
  /**
   * Displays an aggregated apdex score timeseries for a service
   */
  serviceApdexPanel(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
    compact=false,
    description='Apdex is a measure of requests that complete within a tolerable period of time for the service. Higher is better.',
    stableId=null,
    sort='increasing',
  )::
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };

    genericApdexPanel(
      'Latency: Apdex',
      description=description,
      compact=compact,
      stableId=stableId,
      primaryQueryExpr=sliPromQL.apdex.serviceApdexQuery(selectorHash, '$__interval', worstCase=true),
      legendFormat='{{ type }} service',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
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

  /**
   * Displays an apdex score timeseries for a single SLI for a single service
   */
  sliApdexPanel(
    serviceType,
    serviceStage,
    sliName,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      sliName: sliName,
    };
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage, component: sliName };

    genericApdexPanel(
      '%(sliName)s Apdex' % formatConfig,
      primaryQueryExpr=sliPromQL.apdex.sliApdexQuery(selectorHash, '$__interval'),
      legendFormat='{{ component }} apdex',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
      stableId='sli-%(sliName)s-apdex' % formatConfig,
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* apdex$/'))
    .addDataLink({
      url: '/d/alerts-component_multiburn_apdex?${__url_time_range}&${__all_variables}&var-type=%(serviceType)s&var-component=%(sliName)s' % formatConfig,
      title: 'SLI Apdex Multi-Burn Analysis',
      targetBlank: true,
    }),

  /**
   * Apdex score timeseries for a single SLI on a single node
   */
  sliNodeApdexPanel(
    serviceType,
    sliName,
    selectorHash,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      sliName: sliName,
    };

    genericApdexPanel(
      '🖥 Per-Node %(sliName)s Apdex' % formatConfig,
      primaryQueryExpr=sliPromQL.apdex.sliNodeApdexQuery(selectorHash, '$__interval'),
      legendFormat='{{ fqdn }} {{ component }} apdex',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
      sort='increasing',
      legend_show=false,
      linewidth=1,
      stableId='node-sli-%(sliName)s-apdex' % formatConfig,
    )
    .addDataLink({
      url: '/d/alerts-component_node_multiburn_apdex?${__url_time_range}&${__all_variables}&var-type=%(serviceType)s&var-fqdn=${__series.labels.fqdn}' % formatConfig,
      title: 'Component/Node Apdex Multi-Burn Analysis',
      targetBlank: true,
    }),

  /**
   * Apdex score timeseries for all SLIs aggregated on a node
   */
  serviceNodeApdexPanel(
    serviceType,
    selectorHash,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    genericApdexPanel(
      'Node Latency: Apdex',
      primaryQueryExpr=sliPromQL.apdex.serviceNodeApdexQuery(selectorHash, '$__interval'),
      legendFormat='{{ fqdn }}',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
      stableId='node-latency-%(serviceType)s-apdex' % { serviceType: serviceType },
    ),

  /**
   * Aggregated error ratio timeseries for a service
   */
  serviceErrorRatePanel(
    serviceType,
    serviceStage,
    environmentSelectorHash=defaultEnvironmentSelector,
    compact=false,
    includeLastWeek=true,
    stableId=null,
  )::
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };
    local formatConfig = {
      serviceType: serviceType,
    };

    genericErrorPanel(
      'Error Ratios',
      compact=compact,
      stableId=stableId,
      primaryQueryExpr=sliPromQL.errorRate.serviceErrorRateQuery(selectorHash, '$__interval', worstCase=true),
      legendFormat='{{ type }} service',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
    )
    .addTarget(  // Primary metric (avg)
      promQuery.target(
        sliPromQL.errorRate.serviceErrorRateQuery(selectorHash, '$__interval', worstCase=false),
        legendFormat='{{ type }} service (avg)',
      )
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
      url: '/d/alerts-service_multiburn_error?${__url_time_range}&${__all_variables}&var-type=%(serviceType)s' % formatConfig,
      title: 'Service Error-Rate Multi-Burn Analysis',
      targetBlank: true,
    }),

  /**
   * Error ratio timeseries panel for a single SLI for a single service
   */
  sliErrorRatePanel(
    serviceType,
    serviceStage,
    sliName,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      sliName: sliName,
    };
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage, component: sliName };

    genericErrorPanel(
      '%(sliName)s SLI Error-Rate' % formatConfig,
      stableId='sli-%(sliName)s-error-rate' % formatConfig,
      linewidth=1,
      primaryQueryExpr=sliPromQL.errorRate.sliErrorRateQuery(selectorHash),
      legendFormat='{{ component }} error rate',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* error rate$/'))
    .addDataLink({
      url: '/d/alerts-component_multiburn_error?${__url_time_range}&${__all_variables}&var-type=%(serviceType)s&var-component=%(sliName)s' % formatConfig,
      title: 'SLI Error-Rate Multi-Burn Analysis',
      targetBlank: true,
    }),

  /**
   * Timeseries for a single SLI on a single node for a single service
   */
  sliNodeErrorRateQuery(
    serviceType,
    sliName,
    selectorHash,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      sliName: sliName,
    };

    genericErrorPanel(
      '🖥 Per-Node %(sliName)s SLI Error Rates' % formatConfig,
      stableId='sli-%(sliName)s-per-node-error-rate' % formatConfig,
      linewidth=1,
      legend_show=false,
      primaryQueryExpr=sliPromQL.errorRate.sliNodeErrorRateQuery(selectorHash),
      legendFormat='{{ fqdn }} {{ component }} error rate',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
    )
    .addDataLink({
      url: '/d/alerts-component_node_multiburn_error?${__url_time_range}&${__all_variables}&var-type=%(serviceType)s&var-fqdn=${__series.labels.fqdn}' % formatConfig,
      title: 'Per-Node SLI Error-Rate Multi-Burn Analysis',
      targetBlank: true,
    }),

  /**
   * Returns a timeseries for a node-level error ratios, aggregated over all SLIs
   */
  serviceNodeErrorRatePanel(
    serviceType,
    selectorHash,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    genericErrorPanel(
      'Node Error Ratio',
      primaryQueryExpr=sliPromQL.errorRate.serviceNodeErrorRateQuery(selectorHash),
      legendFormat='{{ fqdn }} error rate',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
      stableId='node-%(serviceType)s-error-ratio' % { serviceType: serviceType },
    ),

  /**
   * Timeseries aggregated operation rate across all SLIs in a service
   */
  serviceOperationRatePanel(
    serviceType,
    serviceStage,
    compact=false,
    environmentSelectorHash=defaultEnvironmentSelector,
    stableId=null,
  )::
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage };

    genericOperationRatePanel(
      'RPS - Service Requests per Second',
      compact=compact,
      stableId=stableId,
      primaryQueryExpr=sliPromQL.opsRate.serviceOpsRateQuery(selectorHash, '$__interval'),
      legendFormat='{{ type }} service',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
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

  /**
   * Timeseries for the operation rate of a single SLI in a service
   */
  sliOpsRatePanel(
    serviceType,
    serviceStage,
    sliName,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      sliName: sliName,
    };
    local selectorHash = environmentSelectorHash { type: serviceType, stage: serviceStage, component: sliName };

    genericOperationRatePanel(
      '%(sliName)s SLI RPS - Requests per Second' % formatConfig,
      primaryQueryExpr=sliPromQL.opsRate.sliOpsRateQuery(selectorHash, '$__interval'),
      legendFormat='{{ component }} RPS',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
      linewidth=1
    )
    .addSeriesOverride(seriesOverrides.goldenMetric('/.* RPS$/')),

  /**
   * Timeseries for a single SLI on a single node for a single service
   */
  sliNodeOperationRatePanel(
    serviceType,
    sliName,
    selectorHash,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    local formatConfig = {
      serviceType: serviceType,
      sliName: sliName,
    };

    genericOperationRatePanel(
      '🖥 Per-Node %(sliName)s SLI RPS - Requests per Second' % formatConfig,
      primaryQueryExpr=sliPromQL.opsRate.sliNodeOpsRateQuery(selectorHash, '$__interval'),
      legendFormat='{{ fqdn }} {{ component }} RPS',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
      linewidth=1,
    ),

  serviceNodeOperationRatePanel(
    serviceType,
    selectorHash,
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    genericOperationRatePanel(
      'Node RPS - Requests per Second',
      primaryQueryExpr=sliPromQL.opsRate.serviceNodeOpsRateQuery(selectorHash, '$__interval'),
      legendFormat='{{ fqdn }}',
      environmentSelectorHash=environmentSelectorHash,
      serviceType=serviceType,
    ),

  /**
   * Return utilization rates panel for a service
   */
  utilizationRatesPanel(
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

  /**
   * Returns a row with key metrics for service
   */
  headlineMetricsRow(
    serviceType,
    serviceStage,
    startRow,
    rowTitle='🌡️ Aggregated Service Level Indicators (𝙎𝙇𝙄𝙨)',
    environmentSelectorHash=defaultEnvironmentSelector,
  )::
    layout.grid([
      row.new(title=rowTitle, collapse=false),
    ], cols=1, rowHeight=1, startRow=startRow)
    +
    layout.splitColumnGrid([
      [
        self.serviceApdexPanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash),
        statusDescription.serviceApdexStatusDescriptionPanel(environmentSelectorHash { type: serviceType, stage: serviceStage }),
      ],
      [
        self.serviceErrorRatePanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash),
        statusDescription.serviceErrorStatusDescriptionPanel(environmentSelectorHash { type: serviceType, stage: serviceStage }),
      ],
      [
        self.serviceOperationRatePanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash),
      ],
      [
        self.utilizationRatesPanel(serviceType, serviceStage, compact=true, environmentSelectorHash=environmentSelectorHash),
      ],
    ], [4, 1], startRow=startRow + 1),
}
