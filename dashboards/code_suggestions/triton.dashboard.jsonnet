// This uses a stock Triton dashboard obtained externally
// and configures it for GitLab's Grafana setup
// Replace the `triton_server.json` file with a new file
// if one is available. Any changes can be mixed-in on this file.
local templates = import 'grafana/templates.libsonnet';
local stockDashboard = import 'triton_server.json.txt';

stockDashboard {
  id: null,
  annotations: {
    list: [],
  },
  templating+: {
    list+: [templates.ds],
  },
  panels: std.map(
    function(p)
      p {
        datasource: {
          uid: '$PROMETHEUS_DS',
        },
      },
    stockDashboard.panels
  ),
  uid: 'triton',
}
