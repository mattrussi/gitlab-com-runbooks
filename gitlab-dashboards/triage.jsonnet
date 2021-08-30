local metricsCatalog = import 'gitlab-monitoring/servicemetrics/metrics-catalog.libsonnet';

[
  { name: 'Web Frontend: gitlab.com web traffic', definition: metricsCatalog.getService('web') },
  { name: 'API: gitlab.com/api traffic', definition: metricsCatalog.getService('api') },
  { name: 'Git: git ssh and https traffic', definition: metricsCatalog.getService('git') },
  { name: 'CI runners', definition: metricsCatalog.getService('ci-runners') },
  { name: 'Container registry', definition: metricsCatalog.getService('registry') },
]
