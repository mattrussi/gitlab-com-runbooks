local saturationTypes = [
  import 'kube_container_cpu.libsonnet',
];

std.foldl(
  function(memo, module)
    memo + module,
  saturationTypes,
  {}
)
