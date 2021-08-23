local serviceCatalog = import 'service_catalog.libsonnet';
local keyServices = serviceCatalog.findKeyBusinessServices(includeZeroScore=true);

local keyServiceNames = std.sort(std.map(function(service) service.name, keyServices));
local keyServiceRegExp = std.join('|', keyServiceNames);

// Currently this is fixed, but ideally need have a variable range, like the
// grafana $__range variable supports
local range = '7d';

local slaDashboard =
  {
    dashboard: 'general SLAs',
    links: [
      {
        title: "api: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/api-main/api-overview"
      },
      {
        title: "frontend: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/frontend-main/frontend-overview"
      },
      {
        title: "git: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/git-main/git-overview"
      },
      {
        title: "gitaly: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/gitaly-main/gitaly-overview"
      },
      {
        title: "logging: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/logging-main/logging-overview"
      },
      {
        title: "monitoring: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/monitoring-main/monitoring-overview"
      },
      {
        title: "nfs: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/nfs-main/nfs-overview"
      },
      {
        title: "pages: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/pages-main/pages-overview"
      },
      {
        title: "patroni: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/patroni-main/patroni-overview"
      },
      {
        title: "pgbouncer: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/pgbouncer-main/pgbouncer-overview"
      },
      {
        title: "praefect: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/praefect-main/praefect-overview"
      },
      {
        title: "redis-cache: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/redis-cache-main/redis-cache-overview"
      },
      {
        title: "redis-sidekiq: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/redis-sidekiq-main/redis-sidekiq-overview"
      },
      {
        title: "redis: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/redis-main/redis-overview"
      },
      {
        title: "registry: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/registry-main/registry-overview"
      },
      {
        title: "search: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/search-main/search-overview"
      },
      {
        title: "sidekiq: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/sidekiq-main/sidekiq-overview"
      },
      {
        title: "waf: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/waf-main/waf-overview"
      },
      {
        title: "web-pages: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/web-pages-main/web-pages-overview"
      },
      {
        title: "web: Overview",
        type: "grafana",
        url: "https://dashboards.gitlab.com/d/web-main/web-overview"
      },
      {
        title: 'Platform Triage',
        type: 'grafana',
        url: 'https://dashboards.gitlab.com/d/general-triage/general-platform-triage?orgId=1',
      }, {
        title: 'Capacity Planning',
        type: 'grafana',
        url: 'https://dashboards.gitlab.com/d/general-capacity-planning/general-capacity-planning?orgId=1',
      },
    ],
    panel_groups: [
      {
        group: 'Headline',
        panels: [
          {
            title: 'Weighted Availability Score - GitLab.com',
            type: 'single-stat',
            max_value: 1,
            metrics: [
              {
                id: 'single-stat-weighted-availability',
                // NB: this query takes into account values recorded in Prometheus prior to
                // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689
                // Better fix proposed in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/326
                query: 'avg(clamp_max(avg_over_time(sla:gitlab:ratio{env=~"ops|gprd", environment="gprd", stage="main", monitor=~"global|"}[%(range)s]),1))' % {
                  range: range,
                },
                unit: '%',
                label: 'Weighted Availability Score - GitLab.com',
              },
            ],
          },
          {
            title: 'Overall SLA over time period - gitlab.com',
            type: 'line-chart',
            y_axis: {
              name: 'SLA',
              format: 'percent',
            },
            metrics: [
              {
                id: 'line-chart-overall-sla-time-period',
                // NB: this query takes into account values recorded in Prometheus prior to
                // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689
                // Better fix proposed in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/326
                query_range: 'avg(clamp_max(avg_over_time(sla:gitlab:ratio{env=~"ops|gprd", environment="gprd", stage="main", monitor=~"global|"}[1d]),1))',
                unit: '%',
                label: 'gitlab.com SLA',
                step: 86400,
              },
            ],
          },
        ],
      },
      {
        group: 'SLA Trends - Per primary service',
        panels:
          [
            {
              title: 'Primary Services Average Availability for Period - %(type)s' % { type: type },
              type: 'single-stat',
              max_value: 1,
              metrics: [
                {
                  id: 'single-stat-sla-trend-%(type)s' % {
                    type: type,
                  },
                  // NB: this query takes into account values recorded in Prometheus prior to
                  // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689
                  // Better fix proposed in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/326
                  query: 'avg(avg_over_time(slo_observation_status{env=~"ops|gprd", environment="gprd", stage="main", type="%(type)s"}[%(range)s]))' % {
                    type: type,
                    range: range,
                  },
                  unit: '%',
                  label: 'Primary Services Average Availability for Period - %(type)s' % { type: type },
                },
              ],
            }
            for type in keyServiceNames
          ]
          +
          [
            {
              title: 'SLA Trends - Primary Services',
              type: 'line-chart',
              y_axis: {
                name: 'SLA',
                format: 'percent',
              },
              metrics: [
                {
                  id: 'line-chart-sla-trends-primary-services',
                  // NB: this query takes into account values recorded in Prometheus prior to
                  // https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/9689
                  // Better fix proposed in https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/326
                  query_range: 'clamp_min(clamp_max(avg(avg_over_time(slo_observation_status{env=~"ops|gprd", environment="gprd", stage="main", type=~"%(keyServiceRegExp)s"}[1d])) by (type),1),0)' % {
                    keyServiceRegExp: keyServiceRegExp,
                  },
                  unit: '%',
                  label: '{{type}}',
                  step: 86400,
                },
              ],
            },
          ],
      },
    ],
  };

{
  'sla-dashboard.yml': std.manifestYamlDoc(slaDashboard),
}
