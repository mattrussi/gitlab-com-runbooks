# Saturation Monitoring

This module contains saturation-monitoring definitions. These are used to monitor saturation in a GitLab instance.

More details can be found at <https://about.gitlab.com/handbook/engineering/infrastructure/capacity-planning/>.


## Capacity Planning

The definitions are also used for capacity planning purposes in [Tamland](https://gitlab.com/gitlab-com/gl-infra/tamland).

A saturation point may override default capacity planning parameters:

```
{
  pg_int4_id: resourceSaturationPoint({
    title: 'Postgres int4 ID capacity',
    // ... truncated for brevity
    capacityPlanning: {
      strategy: 'quantile95_1w',  // default: quantile95_1h
      forecast_days: 365,         // default: 90
      historical_days: 730,       // default: 360
    },
  }),
}
```
