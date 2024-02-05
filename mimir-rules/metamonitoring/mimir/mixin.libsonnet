local mimir = import 'mimir/mixin.libsonnet';

mimir {
  _config+:: {
    product: 'Mimir',

    additionalAlertLabels: {
      team: 'scalability:observability',
      env: 'ops',
    },
  },
}
