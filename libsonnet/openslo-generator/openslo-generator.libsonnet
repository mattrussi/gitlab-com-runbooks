local openSLOServiceDefinition(serviceDefinition) =
{
    apiVersion: 'openslo/v1alpha',
    kind: 'Service',
    metadata: {
      name: serviceDefinition.type,
      title: '%s Service' % [serviceDefinition.type]
    },
    spec: {
      description: 'The %s service for GitLab.com' % [serviceDefinition.type]
    },
  };

local openSLOApdexDefinition(serviceDefinition, sli) =
{
  apiVersion: 'openslo/v1alpha',
  kind: 'SLO',
  metadata: {
    name: 'service-%(type)s-%(component)s-apdex' % { type: serviceDefinition.type, component: sli.name },
  },
  spec: {
    service: serviceDefinition.type,
    description: sli.description,
    budgetingMethod: 'Occurrences',
    objectives: [{
      ratioMetrics: {
          good: {
            source: "prometheus",
            queryType: "promql",
            query: 'sum(rate(apiserver_request_total{code!~"(5..|429)"}[{{.window}}]))',
          },
          total: {
            source: "prometheus",
            queryType: "promql",
            query: 'sum(rate(apiserver_request_total[{{.window}}]))'
          },
        target: serviceDefinition.monitoringThresholds.apdexScore
      }
    }],
    timeWindows: [{
      count: 30,
      unit: 'Day'
    }],
  }
};

// local openSLOErrorDefinition(serviceDefinition, sli) =
// {

// };

local generateOpenSLODefinitionsForService(serviceDefinition) =
{
  // ['service-%s.yml' % [serviceDefinition.type]]: std.manifestYamlDoc(openSLOServiceDefinition(serviceDefinition))
}
  +
  std.foldl(
    function(memo, sli)
      local formatConfig = { type: serviceDefinition.type, component: sli.name };
      memo
      +
      (
        if sli.hasApdex() && std.objectHas(serviceDefinition.monitoringThresholds, 'apdexScore') then
        {
          ['service-%(type)s-%(component)s-apdex.yml' % formatConfig]: std.manifestYamlDoc(openSLOApdexDefinition(serviceDefinition, sli))
        }
        else
        {}
      )
      // +
      // (
      //   if sli.hasErrorRate() then
      //   {
      //       ['service-%(type)s-%(component)s-errors.yml' % formatConfig]: std.manifestYamlDoc(openSLOErrorDefinition(serviceDefinition, sli))
      //   }
      //   else
      //   {}
      // )
      ,
    serviceDefinition.listServiceLevelIndicators(),
    {},
  );

{
  generateOpenSLODefinitionsForService(serviceDefinition):: generateOpenSLODefinitionsForService(serviceDefinition)
}
