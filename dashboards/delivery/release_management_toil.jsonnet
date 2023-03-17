local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local template = grafana.template;

local numberOfAutoDeployJobRetriesQuery = 'sort_desc(sum(increase(delivery_webhooks_auto_deploy_job_retries[$__range])) by (project) != 0)';
local numberOfAutoDeployJobRetriesByJobQuery = 'sort_desc(sum(increase(delivery_webhooks_auto_deploy_job_retries[$__range])) by (project, job_name) != 0)';
local secondsLostBetweenRetriesQuery = 'sum by(job_name)(increase(delivery_webhooks_auto_deploy_job_failure_lost_seconds[$__range]) != 0)';

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
    unit: 'm',
  },
];

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

.addPanels(layout.singleRow([
  basic.table(
    title='🔄 Number of auto-deploy retries per Project 🔄',
    styles=styles,
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
  ),
], rowHeight=8, startRow=0))

.addPanels(layout.singleRow([
  basic.table(
    title='🔄 Number of auto-deploy retries per job 🔄',
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
  ),
], rowHeight=8, startRow=100))
.trailer()
