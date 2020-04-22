local marqueeDashboard = {
  dashboard: 'marquee: Customer Dashboard',
  templating: {
    variables: {
      environment: 'gprd',
      customer: '1',
      web_request_interval: '2m',
      web_errors_interval: '2m',
      error_rate_interval: '2m',
    },
  },
  panel_groups: [
    {
      group: 'Web',
      panels: [
        {
          title: 'Web Latency',
          type: 'area-chart',
          y_axis: {
            name: 'SLA',
          },
          metrics: [
            {
              id: 'web-latency-marquee-customer',
              query_range: 'marquee_customers_request_duration_seconds{env="{{environment}}", salesforce_url="https://gitlab.my.salesforce.com/{{customer}}"}',
              unit: '%',
              label: 'p95',
            },
          ],
        },
        {
          title: 'Web Requests / Second',
          type: 'area-chart',
          metrics: [
            {
              id: 'web-requests-marquee-customer',
              query_range: 'rate(marquee_customers_requests_total{env="{{environment}}", salesforce_url="https://gitlab.my.salesforce.com/{{customer}}"}[{{web_request_interval}}])',
              unit: '%',
              label: 'RPS',
            },
          ],
        },
        {
          title: 'Web Errors',
          type: 'area-chart',
          metrics: [
            {
              id: 'web-errors-marquee-customer',
              query_range: 'increase(marquee_customers_requests_server_errors_total{env="{{environment}}", salesforce_url="https://gitlab.my.salesforce.com/{{customer}}"}[{{web_errors_interval}}])',
              unit: '%',
              label: 'Errors',
            },
          ],
        },
        {
          title: 'Error Rate',
          type: 'area-chart',
          y_axis: {
            name: 'Percent',
          },
          metrics: [
            {
              id: 'error-rate-marquee-customer',
              query_range: 'clamp_min(clamp_max(rate(marquee_customers_requests_server_errors_total{env="{{environment}}", salesforce_url="https://gitlab.my.salesforce.com/{{customer}}"}[{{error_rate_interval}}]) / rate(marquee_customers_requests_total{env="{{environment}}", salesforce_url="https://gitlab.my.salesforce.com/{{customer}}"}[{{error_rate_interval}}]),1),0)',
              unit: '%',
              label: 'Error Rate(%)',
            },
          ],
        },
      ],
    },
  ],
};

{
  'marquee-dashboard.yml': std.manifestYamlDoc(marqueeDashboard),
}
