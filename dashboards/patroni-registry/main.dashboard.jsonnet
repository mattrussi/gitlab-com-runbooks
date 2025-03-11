local panels = import 'gitlab-dashboards/patroni-panels.libsonnet';

panels.patroni('patroni-registry', 'gitlab-registry', useTimeSeriesPlugin=true)
