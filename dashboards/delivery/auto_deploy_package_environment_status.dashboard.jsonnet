local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local basic = import 'grafana/basic.libsonnet';
local layout = import 'grafana/layout.libsonnet';

local env_state_legend_content = |||
    - Ready - The environment is idle and ready to accept a new deployment.
    - locked - There is an ongoing operation on the environment. Either a deployment, or a post-deploy migration.
    - awaiting_promotion - The environment is idle, and there is a package available for promotion. This only applies to gstg or gprd.
    - baking_time - A deployment just completed and the package is now considered to be "baking" on the environment. Baking usually lasts for 30 mins. This only applies to gprd-cny.
|||;

local lock_state_legend_content = |||
  - locked_deployment - There is an ongoing deployment to the environment.
  - locked_deployment_failed - The last deployment to the environment failed.
  - locked_qa - A QA pipeline is running against this environment.
  - locked_qa_failed - The last QA pipeline on the environment failed.
  - locked_post_deploy_migration - Post deploy migrations are being executed on this environment.
  - locked_post_deploy_migration_failed - Post deploy migrations on the environment has failed.
|||;

local lastDeployPackageStateQuery ='last_over_time(delivery_auto_deploy_package_state[$__range]) >= 1';
local lastDeployCompletedQuery = 'last_over_time(delivery_deployment_completed[$__range])';
local lastDeployCompletedandPackageState = 'last_over_time(delivery_auto_deploy_package_state[$__range]) >= 1 and on (version) last_over_time(delivery_deployment_completed[$__range])';

local autoDeployPackagesTable =
  basic.table(
    title='Auto deploy packages',
    description="Displays the last 10 auto deploy packages and their statuses",
    styles=null,
    queries=[
        lastDeployPackageStateQuery,
        lastDeployCompletedQuery,
        lastDeployCompletedandPackageState,
    ],
    transformations=[
      {
        id: 'filterFieldsByName',
        options: {
          include: {
            names: ['pkg_state','version','target_env'],
          },
        },
      },
    ],
  );

basic.dashboard(
  'Auto deploy environment states',
  tags=['release'],
  editable=true,
  time_from='now-6h',
  time_to='now',
  includeStandardEnvironmentAnnotations=false,
  includeEnvironmentTemplate=false,
)
.addPanels(
    layout.singleRow([
        grafana.text.new(
            title='Environment state legend',
            mode='markdown',
            content=env_state_legend_content,
        ),
        grafana.text.new(
            title='Lock state legend',
            mode='markdown',
            content=lock_state_legend_content,
        ),
    ],startRow=0)
)
.addPanels(
  layout.singleRow(
    [
      autoDeployPackagesTable
    ],startRow=100
    )
)
.trailer()
