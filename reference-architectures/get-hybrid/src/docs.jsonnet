local services = (import 'gitlab-metrics-config.libsonnet').monitoredServices;

// This jsonnet file is used by `scripts/generate-reference-architecture-docs.sh` to
// generate documentation that is embedded with the README.md file for this
// reference-architecture.
//
// It will be called when scripts/generate-reference-architecture-configs.sh is executed.
local generateDocsForService(service) =
  local slis = service.listServiceLevelIndicators();

  // header +
  std.join('', std.map(function(sli) |||
    | `%(serviceType)s` | `%(name)s` | %(description)s | %(apdexMarker)s | %(errorMarker)s | ✅ |
  ||| % sli {
    serviceType: service.type,
    description: std.strReplace(sli.description, '\n', ' '),
    apdexMarker:
      if sli.hasApdex() then
        '✅' + (if sli.hasApdexSLO() then ' SLO: %g%%' % [sli.monitoringThresholds.apdexScore * 100] else '')
      else
        '-',
    errorMarker:
      if sli.hasErrorRate() then
        '✅' + (if sli.hasErrorRateSLO() then ' SLO: %g%%' % [sli.monitoringThresholds.errorRatio * 100] else '')
      else
        '-',
  }, slis));

{
  'README.snippet.md':
    |||
      ## Service Level Indicators

      | **Service** | **Component** | **Description** | **Apdex** | **Error Ratio** | **Operation Rate** |
      | ----------- | ------------- | --------------- | --------- | --------------- | ------------------ |
    ||| + std.join('',
                   std.map(
                     generateDocsForService, services
                   )),
}
