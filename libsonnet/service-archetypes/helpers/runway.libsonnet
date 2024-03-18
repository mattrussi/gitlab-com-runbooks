// Labels set by
// https://gitlab.com/gitlab-com/gl-infra/platform/runway/runwayctl/-/blob/main/reconciler/templates/otel-config.yaml.tftpl
local commonLabels = [
  'region',
];

{
  commonLabels:: commonLabels,
}
