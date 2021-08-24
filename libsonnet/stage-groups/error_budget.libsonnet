local slaTarget = (import 'metrics-config.libsonnet').slaTarget;

{
  /**
  * Configuration for the error budget
  * slaTarget: The target availability in a float, currently based on our overal slaTarget
  * range: 28d (1 month)
  */
  slaTarget: slaTarget,
  range: '28d',

  /**
  * The queries and helper methods used for building PromQL queries for the error
  * budgets
  */
  queries: (import 'stage-groups/error-budget/queries.libsonnet').init(self.slaTarget, self.range),

  /**
  * Panels for rendering on a grafana dashboard
  */
  panels: (import 'stage-groups/error-budget/panels.libsonnet').init(self.queries, self.slaTarget, self.range),
}
