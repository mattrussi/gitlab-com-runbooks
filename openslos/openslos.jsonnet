local opensloGenerator = import 'openslo-generator/openslo-generator.libsonnet';
local services = import './services/all.jsonnet';


std.foldl(
  function(memo, service)
    memo + opensloGenerator.generateOpenSLODefinitionsForService(service),
  services,
  {}
)
