local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local quantilePanel = import 'grafana/quantile_panel.libsonnet';
local templates = import 'grafana/templates.libsonnet';
local metricsCatalog = import 'metrics-catalog.libsonnet';
local platformLinks = import 'platform_links.libsonnet';
local selectors = import 'promql/selectors.libsonnet';

local graphPanel = grafana.graphPanel;
local row = grafana.row;

local linksForService(type) =
  [
    platformLinks.backToOverview(type),
    platformLinks.dynamicLinks(type + ' Detail', 'type:' + type),
    platformLinks.kubenetesDetail(type),
  ];

local panelsForDeployment(serviceType, deployment, selectorHash) =
  local containerSelectorHash = selectorHash {
    type: serviceType,
    deployment: deployment,
  };

  local formatConfig = {
    type: serviceType,
    deployment: deployment,
    containerSelector: selectors.serializeHash(containerSelectorHash),
  };

  [
    basic.timeseries(
      title='%(deployment)s Deployment: CPU' % formatConfig,
      query=|||
        sum by(cluster) (
          rate(
            container_cpu_usage_seconds_total:labeled{
              %(containerSelector)s
            }[$__rate_interval]
          )
        )
      ||| % formatConfig,
      format='short',  // We measure this in total number of cores across the whole fleet, not percentage of a single core
      linewidth=1,
      legendFormat='{{ cluster }}',
    ),
    basic.timeseries(
      title='%(deployment)s Deployment: Memory' % formatConfig,
      query=|||
        sum by(cluster) (
          container_memory_working_set_bytes:labeled{
            %(containerSelector)s
          }
        )
      ||| % formatConfig,
      format='bytes',
      linewidth=1,
      legendFormat='{{ cluster }}',
    ),
    basic.networkTrafficGraph(
      title='%(deployment)s Deployment: Network IO' % formatConfig,
      sendQuery=|||
        sum by(cluster) (
          rate(
            container_network_transmit_bytes_total:labeled{
              container="POD",
              %(containerSelector)s
            }[$__rate_interval]
          )
        )
      ||| % formatConfig,
      receiveQuery=|||
        sum by(cluster) (
          rate(
            container_network_receive_bytes_total:labeled{
              container="POD",
              %(containerSelector)s
            }[$__rate_interval]
          )
        )
      ||| % formatConfig,
      legendFormat='{{ cluster }}',
    ),
  ];

local dashboardsForService(type) =
  local serviceInfo = metricsCatalog.getService(type);
  local deployments = std.objectFields(serviceInfo.kubeResources);
  local selector = {
    env: '$environment',
    environment: '$environment',
    type: type,
    stage: '$stage',
  };

  {
    'kube-containers':
      basic.dashboard(
        'Kube Containers Detail',
        tags=[type, 'type:' + type, 'kube', 'kube detail'],
      )
      .addTemplate(templates.stage)
      .addPanels(
        layout.rows(
          std.flatMap(
            function(deployment)
              [
                row.new(title='%s deployment' % [deployment]),
              ]
              +
              std.map(
                function(container)
                  local formatConfig = { container: container, type: type, deployment: deployment };
                  [/* row */
                   quantilePanel.timeseries(
                     title=container + ' container CPU',
                     query=|||
                       rate(
                         container_cpu_usage_seconds_total:labeled{
                           type="%(type)s",
                           env="$environment",
                           environment="$environment",
                           stage="$stage",
                           container="%(container)s",
                           deployment="%(deployment)s"
                          }[$__rate_interval]
                        )
                     ||| % formatConfig,
                     format='percentunit',
                     linewidth=1,
                     legendFormat='%s Container CPU' % [container],
                   ),
                   quantilePanel.timeseries(
                     title=container + ' container Memory',
                     query=|||
                       container_memory_working_set_bytes:labeled{
                         type="%(type)s",
                         env="$environment",
                         environment="$environment",
                         stage="$stage",
                         container="%(container)s",
                         deployment="%(deployment)s"
                        }
                     ||| % formatConfig,
                     format='bytes',
                     linewidth=1,
                     legendFormat='%s Container Memory' % [container],
                   ),
                  ],
                serviceInfo.kubeResources[deployment].containers
              ),
            deployments
          ),
          rowHeight=8
        )
      )
      .trailer()
      + {
        links+: linksForService(type),
      },

    'kube-deployments':
      basic.dashboard(
        'Kube Deployment Detail',
        tags=[type, 'type:' + type, 'kube', 'kube detail'],
      )
      .addTemplate(templates.stage)
      .addPanels(
        layout.rows(
          std.flatMap(
            function(deployment)
              [
                row.new(title='%s deployment' % [deployment]),
              ]
              +
              [
                panelsForDeployment(type, deployment, selector),
              ],
            deployments
          ),
          rowHeight=8
        )
      )
      .trailer()
      + {
        links+: linksForService(type),
      },
  };

local deploymentOverview(type, selector, startRow=1) =
  local serviceInfo = metricsCatalog.getService(type);
  local deployments = std.objectFields(serviceInfo.kubeResources);

  // Add links to direct users to kubernetes specific dashboards
  local links = [{
    title: '☸️ %s Kubernetes Deployment Detail' % [type],
    url: '/d/%s-kube-deployments?${__url_time_range}&${__all_variables}' % [type],
  }, {
    title: '☸️ %s Kubernetes Container Detail' % [type],
    url: '/d/%s-kube-containers?${__url_time_range}&${__all_variables}' % [type],
  }];

  layout.rows(
    std.map(
      function(deployment)
        std.map(
          function(panel)
            panel {
              links: links,
            },
          panelsForDeployment(type, deployment, selector)
        ),
      deployments
    ),
    rowHeight=8,
    startRow=startRow
  );

{
  // Returns a set of kubernetes dashboards for a given service
  dashboardsForService:: dashboardsForService,

  // Generates a set of panels with an overview of the deployment
  deploymentOverview:: deploymentOverview,
}
