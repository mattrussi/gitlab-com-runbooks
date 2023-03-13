local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';
local template = grafana.template;

local numberOfAutoDeployJobRetriesQuery = 'sort_desc(sum(increase(delivery_webhooks_auto_deploy_job_retries[$__range])) by (project) != 0)';
local numberOfAutoDeployJobRetriesByJobQuery = 'sort_desc(sum(increase(delivery_webhooks_auto_deploy_job_retries[$__range])) by (project, job_name) != 0)';
local secondsLostBetweenRetriesQuery = 'sum by(job_name)(delivery_webhooks_auto_deploy_job_failure_lost_seconds)';

local styles = [
  {  // remove decimal points
    type: 'number',
    pattern: 'Value',
    decimals: 0,
    mappingType: 1,
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

.addPanels(layout.singleRow([
  basic.table(
    title='Time lost between retries',
    styles=styles,
    queries=[secondsLostBetweenRetriesQuery],
    sort=4,
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
], rowHeight=8, startRow=0))

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
