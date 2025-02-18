{
  sync_id: 'incident-io/catalog',
  pipelines: [
    {
      sources: [
        {
          exec: { command: [
            'yq',
            'eval',
            '.services',
            'service-catalog.yml',
          ] },
        },
      ],
      outputs: [
        {
          name: 'Services',
          description: 'GitLab Services Catalog',
          type_name: 'Custom["Service"]',
          categories: ['service'],
          source: {
            name: '$.name',
            external_id: '$.name',
          },
          attributes: [
            {
              id: 'tier',
              name: 'Tier',
              type: 'String',
              source: '$.tier',
            },
            {
              id: 'description',
              name: 'Description',
              type: 'String',
              source: '$.friendly_name',
            },
            {
              id: 'teams',
              name: 'Teams',
              type: 'Custom["GitlabTeam"]',
              array: true,
              source: '$.teams',
            },
            {
              id: 'owner',
              name: 'Owner',
              type: 'Custom["GitlabTeam"]',
              source: '$.owner',
            },
          ],
        },
      ],
    },
    {
      sources: [{
        exec: { command: [
          'yq',
          'eval',
          '.teams',
          'teams.yml',
        ] },
      }],
      outputs: [
        {
          name: 'GitLab Teams',
          description: 'Teams from GitLab',
          type_name: 'Custom["GitlabTeam"]',
          categories: ['team'],
          source: {
            name: '$.name',
            external_id: '$.name',
          },
          attributes: [
            {
              id: 'maanger',
              name: 'Manager',
              type: 'User',
              source: '$.manager',
            },
            {
              id: 'slack_channel',
              name: 'Team Slack Channel',
              type: 'SlackChannel',
              source: '$.slack_channel',
            },
            {
              id: 'slack_error_budget_channel',
              name: 'Slack Error Budget Channel',
              type: 'SlackChannel',
              source: '$.slack_error_budget_channel',
            },
            {
              id: 'product_stage_group',
              name: 'Product Stage Group',
              type: 'String',
              source: '$.product_stage_group',
            },
            {
              id: 'pagerduty_service',
              name: 'PagerDuty Service',
              type: 'PagerDutyService',
              source: '$.pagerduty_service',
            },
          ],
        },
      ],
    },
  ],
}
