local railsController = import 'gitlab-monitoring/gitlab-dashboards/rails_controller_common.libsonnet';

railsController.dashboard(type='api', defaultController='Grape', defaultAction='GET /api/projects')
