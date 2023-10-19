local defaults = {
  baseURL: 'https://thanos.ops.gitlab.net',
  defaultSelectors: {
    env: 'gprd',
    stage: 'main',
  },
  serviceLabel: 'type',
  queryTemplates: {
    quantile95_1w: 'max(gitlab_component_saturation:ratio_quantile95_1w{%s})',
    quantile99_1w: 'max(gitlab_component_saturation:ratio_quantile99_1w{%s})',
    quantile95_1h: 'max(quantile_over_time(0.95, gitlab_component_saturation:ratio{%s}[1h]))',
  },
};

{
  defaults:: defaults,
}
