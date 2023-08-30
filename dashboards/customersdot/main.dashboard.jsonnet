local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local serviceDashboard = import 'gitlab-dashboards/service_dashboard.libsonnet';
local commonAnnotations = import 'grafana/common_annotations.libsonnet';
local selectors = import 'promql/selectors.libsonnet';
local row = grafana.row;
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';

local selectorHash = {
  environment: '$environment',
  env: '$environment',
  type: 'customersdot',
};
local selectorSerialized = selectors.serializeHash(selectorHash);

serviceDashboard.overview('customersdot')
.addPanel(
  row.new(title='Availability', collapse=true).addPanel(
    basic.slaStats(
      title='CustomersDot Availability',
      query=|||
        sum by (env, environment, tier, type, stage) (
          (
            sum by (env, environment, tier, type, stage) (
              sum_over_time(gitlab_service_apdex:success:rate_1h{env="$environment",type=~"customersdot"}[$__range])
            )
            +
            sum by (env, environment, tier, type, stage) (
              sum_over_time(gitlab_service_ops:rate_1h{env="$environment",type=~"customersdot"}[$__range])
            ) -
            sum by (env, environment, tier, type, stage) (
              sum_over_time(gitlab_service_errors:rate_1h{env="$environment",type=~"customersdot"}[$__range])
            )
          )
        )
        /
        sum by (env, environment, tier, type, stage) (
          (
            sum by (env, environment, tier, type, stage) (
              sum_over_time(gitlab_service_ops:rate_1h{env="$environment",type=~"customersdot"}[$__range])
            )
            +
            sum by (env, environment, tier, type, stage) (
              sum_over_time(gitlab_service_apdex:weight:score_1h{env="$environment",type=~"customersdot"}[$__range])
            )
          )
        )
      |||
    ),
  ),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addPanel(
  row.new(title='💳 Zuora', collapse=true).addPanels(
    layout.grid([
      basic.timeseries(
        title='Client error rate',
        description='Rate of Zuora errors',
        query=|||
          rate(customers_dot_zuora_error_total{%(selector)s}[$__rate_interval])
        ||| % { selector: selectorSerialized },
        interval='1m',
        linewidth=1,
        legend_show=true,
        legendFormat='{{ error }}',
      ),
    ], startRow=1001)
  ),
  gridPos={
    x: 0,
    y: 1000,
    w: 24,
    h: 1,
  }
)
.addAnnotation(commonAnnotations.deploymentsForCustomersDot)
.overviewTrailer()
