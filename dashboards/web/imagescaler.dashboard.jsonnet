local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local templates = import 'grafana/templates.libsonnet';

basic.dashboard(
  title='Workhorse image scaler',
  time_from='now-6h',
  tags=['performance'],
).addTemplate(templates.stage).addPanels(
  layout.grid(
    [
      basic.latencyTimeseries(
        title='p95 PNG scaling duration by width',
        description='95th percentile of time it took to serve a rescaled PNG',
        query=|||
          histogram_quantile(0.95, sum by (le, width) (gitlab_workhorse_image_resize_duration_seconds_bucket{
            type="web", env="$environment", stage="$stage", content_type="image/png"
          }))
        |||,
        legendFormat='{{ width }}',
        format='s',
        min=0.001,
        yAxisLabel='Duration',
        interval='1m',
        intervalFactor=1,
        logBase=10
      ),
      basic.latencyTimeseries(
        title='p95 JPEG scaling duration by width',
        description='95th percentile of time it took to serve a rescaled JPEG',
        query=|||
          histogram_quantile(0.95, sum by (le, width) (gitlab_workhorse_image_resize_duration_seconds_bucket{
            type="web", env="$environment", stage="$stage", content_type="image/jpeg"
          }))
        |||,
        legendFormat='{{ width }}',
        format='s',
        min=0.001,
        yAxisLabel='Duration',
        interval='1m',
        intervalFactor=1,
        logBase=10
      ),
    ],
  ),
)
