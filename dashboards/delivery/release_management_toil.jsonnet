local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';

local numberOfAutoDeployJobRetriesQuery = 'sort_desc(sum(increase(delivery_webhooks_auto_deploy_job_retries[$__range])) by (project) != 0)';
local numberOfAutoDeployJobRetriesByJobQuery = 'sort_desc(sum(increase(delivery_webhooks_auto_deploy_job_retries[$__range])) by (project, job_name) != 0)';
local incompleteDeploymentsQuery = 'sum by (version) (max_over_time(delivery_deployment_completed[$__range])) < 4';
local secondsLostBetweenRetriesQuery = 'sum by(job_name)(increase(delivery_webhooks_auto_deploy_job_failure_lost_seconds[$__range]) != 0)';
local taggedPackagesTotalByTypesQuery = 'sort_desc(sum(increase(delivery_packages_tagging_total[$__range])) by (pkg_type,security))';

local styles = [
  {  // remove decimal points
    type: 'number',
    pattern: 'Value',
    decimals: 0,
    mappingType: 1,
  },
];

// Adding the unit to the styles array
local timeLostUnit = [
  styles[0] {
    unit: 's',
  },
];

local autoDeployJobRetriesTable =
  basic.table(
    title='Number of auto-deploy job retries per Project',
    description="This table shows the number of auto-deploy job retries per project for the duration chosen. For further insight, refer to the 'Number of auto-deploy retries per job' table, which separates the retries by job name",
    styles=null,
    queries=[numberOfAutoDeployJobRetriesQuery],
    sort=4,  // numerically descending
    transformations=[
      {
        id: 'organize',
        options: {
          excludeByName: {
            Time: true,
          },
          renameByName: {
            project: 'Project',
            Value: 'Total Retries',
          },
        },
      },
    ],
  ) {
    fieldConfig+: {
      overrides: [
        {
          matcher: {
            id: 'byName',
            options: 'Value',
          },
          properties: [
            {  // remove decimals
              id: 'decimals',
              value: 0,
            },
          ],
        },
      ],
    },
  };

local autoDeployJobRetriesByJobTable =
  basic.table(
    title='Number of auto-deploy retries per job',
    description='This table shows the number of auto-deploy job retries per project and per job for the duration chosen.',
    styles=styles,
    queries=[numberOfAutoDeployJobRetriesByJobQuery],
    sort=4,  // numerically descending
    transformations=[
      {
        id: 'organize',
        options: {
          excludeByName: {
            Time: true,
          },
          renameByName: {
            project: 'Project',
            Value: 'Total Retries',
            job_name: 'Job Name',
          },
        },
      },
    ],
  ) {
    fieldConfig+: {
      overrides: [
        {
          matcher: {
            id: 'byName',
            options: 'Value',
          },
          properties: [
            {  // remove decimals
              id: 'decimals',
              value: 0,
            },
          ],
        },
      ],
    },
  };

local taggedReleasesByTypeTable =
  basic.table(
    title='Number of Tagged Releases by Type',
    styles=null,
    query=taggedPackagesTotalByTypesQuery,
    transformations=[
      {  // concatenate the columnns for 'pkg_type' and 'security' to create a new column 'Release Type'
        id: 'calculateField',
        alias: 'Release Type',
        binary: {
          left: 'pkg_type',
          reducer: 'sum',
          right: 'security',
        },
        mode: 'reduceRow',
        reduce: {
          include: ['pkg_type', 'security'],
          reducer: 'allValues',
        },
        options: {
          mode: 'reduceRow',
          reduce: {
            reducer: 'allValues',
            include: ['pkg_type', 'security'],
          },
          replaceFields: false,
          alias: 'Release Type',
        },
      },
      {
        id: 'organize',
        options: {
          excludeByName: {
            Time: true,
            pkg_type: true,
            security: true,
          },
          indexByName: {
            'Release Type': 0,
            Value: 1,
            Time: 2,
            pkg_type: 3,
            security: 4,
          },
        },
      },
      {  // Exclude invalid release types variations
        id: 'filterByValue',
        options: {
          filters: [
            {
              config: {
                id: 'regex',
                options: {
                  value: '^auto_deploy,(?!$|no$).*',
                },
              },
              fieldName: 'Release Type',
            },
            {
              config: {
                id: 'regex',
                options: {
                  value: '^monthly,(?!no$).*',
                },
              },
              fieldName: 'Release Type',
            },
            {
              config: {
                id: 'regex',
                options: {
                  value: '^rc,(?!no$).*',
                },
              },
              fieldName: 'Release Type',
            },
            {
              config: {
                id: 'regex',
                options: {
                  value: '^security,(?!$).*',
                },
              },
              fieldName: 'Release Type',
            },
          ],
          match: 'any',
          type: 'exclude',
        },
      },
    ],
  ) {
    fieldConfig+: {
      overrides: [
        {
          matcher: {
            id: 'byName',
            options: 'Release Type',
          },
          properties: [
            {  // User-friendly release types
              id: 'mappings',
              value: [
                {
                  type: 'value',
                  options: {
                    'auto_deploy,no': {
                      text: 'Auto Deploy',
                    },
                    'auto_deploy,': {
                      text: 'Auto Deploy (deprecated)',  // deprecate once this value hits 0
                    },
                    'rc,no': {
                      text: 'RC',
                    },
                    'patch,no': {
                      text: 'Regular Patch',
                    },
                    'patch,critical': {
                      text: 'Critical Security Patch',
                    },
                    'patch,regular': {
                      text: 'Regular Security Patch',
                    },
                    'monthly,no': {
                      text: 'Monthly',
                    },
                  },
                },
              ],
            },
          ],
        },
        {
          matcher: {
            id: 'byName',
            options: 'Value',
          },
          properties: [
            {  // remove decimals
              id: 'decimals',
              value: 0,
            },
          ],
        },
      ],
    },
  };

local incompleteDeploymentsTable =
  basic.table(
    title='Incomplete Auto-Deployment Versions',
    description='Remember to not count the currently deploying version. Because of of how the delivery_deployment_completed metric works, it will always include the last one that is still deploying by the end of this query range (at the top).',
    styles=null,
    instant=true,
    query=incompleteDeploymentsQuery,
    interval=null,
    intervalFactor=null,
    transformations=[
      {
        id: 'organize',
        options: {
          excludeByName: {
            Time: true,
            Value: true,
          },
          indexByName: {},
          renameByName: {
            version: 'versions (read description)',
          },
        },
      },
    ],
  );

local incompleteDeploymentsStatPanel =
  basic.statPanel(
    title='',
    panelTitle='Total Number of Incomplete Auto-Deployments',
    description='Because of of how the delivery_deployment_completed metric works, it will always include the last one that is still deploying by the end of this query range (at the top). That is why this number is 1 less than the number of rows from the Incomplete Auto-Deploy Versions table.',
    colorMode='value',
    format='table',
    query=incompleteDeploymentsQuery,
    color=[
      { color: 'white', value: null },
    ],
    transformations=[
      {
        id: 'organize',
        options: {
          excludeByName: {
            Time: true,
            Value: true,
          },
          indexByName: {},
          renameByName: {},
        },
      },
      {
        id: 'reduce',
        options: {
          reducers: [
            'changeCount',
          ],
          includeTimeField: false,
          labelsToFields: true,
          mode: 'seriesToRows',
        },
      },
    ],
  );

basic.dashboard(
  'Release Management Toil',
  tags=['release'],
  editable=true,
  time_from='now-7d',
  time_to='now',
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
)

.addPanels(
  layout.singleRow([
    basic.table(
      title='Increase in deployment pipeline duration due to retry of failed jobs',
      description='This panel shows how much the deployment pipeline duration was increased by the need to retry failed jobs. For example,\nif a failed job is retried and succeeds after an hour of the failure, the deployment pipeline duration was increased by an hour.',
      styles=timeLostUnit,
      queries=[secondsLostBetweenRetriesQuery],
      sort={
        col: 1,
        desc: true,
      },
      transformations=[
        {
          id: 'organize',
          options: {
            excludeByName: {
              Time: true,
            },
          },
        },
      ],
    ),
  ], rowHeight=8, startRow=0),
)

.addPanels(
  layout.rowGrid(
    '🔄 Auto Deploy Job Retries 🔄',
    [
      autoDeployJobRetriesTable,
      autoDeployJobRetriesByJobTable,
    ],
    collapse=false,
    rowHeight=8,
    startRow=100,
  )
)

.addPanels(
  layout.rowGrid(
    '🚀 Tagged Releases 🚀',
    [taggedReleasesByTypeTable],
    collapse=false,
    rowHeight=10,
    startRow=200,
  )
)

.addPanels(
  layout.rowGrid(
    '❌ Incomplete/Failed Deployments ❌',
    [
      incompleteDeploymentsTable,
      incompleteDeploymentsStatPanel,
    ],
    collapse=false,
    rowHeight=10,
    startRow=300,
  )
)

.trailer()
