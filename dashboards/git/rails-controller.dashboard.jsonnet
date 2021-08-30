local railsController = import 'gitlab-monitoring/gitlab-dashboards/rails_controller_common.libsonnet';

railsController.dashboard(type='git', defaultController='Repositories::GitHttpController', defaultAction='git_upload_pack')
