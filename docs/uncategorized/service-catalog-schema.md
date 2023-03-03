# GitLab Service Catalog Schema

<p>A catalog of services and teams for GitLab SaaS platforms</p>

<table>
<tbody>
<tr><th>$id</th><td>https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog-schema.json</td></tr>
<tr><th>$schema</th><td>http://json-schema.org/draft-07/schema#</td></tr>
</tbody>
</table>

## Properties

<table><thead><tr><th colspan="2">Name</th><th>Type</th></tr></thead><tbody><tr><td colspan="2"><a href="#teams">teams</a></td><td>Array</td></tr><tr><td colspan="2"><a href="#services">services</a></td><td>Array</td></tr><tr><td colspan="2"><a href="#tiers">tiers</a></td><td>Array</td></tr></tbody></table>



<hr />



## teams


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The list of teams</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    <tr>
      <th>Required</th>
      <td colspan="2">No</td>
    </tr>
    <tr>
      <th>Min Items</th>
      <td colspan="2">1</td>
    </tr>
  </tbody>
</table>



### teams.name


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The unique name of the team</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### teams.url


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The handbook URL of the team</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### teams.url.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### teams.url.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### teams.product_stage_group


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The product stage group of the team. Must match &#x60;group&#x60; key in https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/stages.yml</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### teams.slack_alerts_channel


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The name of the Slack channel to receive alerts for the team. Must omit &#x60;#&#x60; prefix</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    <tr>
      <th>Pattern</th>
      <td colspan="2">^(?!#.*$).*</td>
    </tr>
  </tbody>
</table>




### teams.send_slo_alerts_to_team_slack_channel


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The setting to enable/disable receiving alerts in the team&#x27;s Slack alert channel</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Boolean</td></tr>
    
  </tbody>
</table>




### teams.alerts


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The list of environments for alerts for the team introduced in https://gitlab.com/gitlab-com/runbooks/-/merge_requests/5176</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    <tr>
      <th>Unique Items</th>
      <td colspan="2">true</td>
    </tr>
  </tbody>
</table>




### teams.ignored_components


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The list of components that should not feed into the team&#x27;s error budget</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    <tr>
      <th>Unique Items</th>
      <td colspan="2">true</td>
    </tr>
  </tbody>
</table>




### teams.slack_error_budget_channel


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The name of the Slack channel to receive weekly error budget reports for the team. Must omit &#x60;#&#x60; prefix</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>Array</td></tr><tr><td>String</td></tr></tr>
    
  </tbody>
</table>



### teams.slack_error_budget_channel.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    <tr>
      <th>Unique Items</th>
      <td colspan="2">true</td>
    </tr>
  </tbody>
</table>




### teams.slack_error_budget_channel.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>





### teams.send_error_budget_weekly_to_slack


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The setting to enable/disable receiving weekly error budget reports in the team&#x27;s Slack error budget channel</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Boolean</td></tr>
    
  </tbody>
</table>




### teams.manager_slug


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">DEPRECATED: The manager&#x27;s slug for the team</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### teams.manager_slug.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### teams.manager_slug.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### teams.engagement_policy


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">DEPRECATED: The engagement policy of the team</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### teams.engagement_policy.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### teams.engagement_policy.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### teams.oncall_schedule


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">DEPRECATED: The on-call schedule of the team</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### teams.oncall_schedule.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### teams.oncall_schedule.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### teams.slack_channel


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">DEPRECATED: The Slack channel of the team</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### teams.slack_channel.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### teams.slack_channel.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>








## services


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The list of services</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    <tr>
      <th>Required</th>
      <td colspan="2">No</td>
    </tr>
    <tr>
      <th>Min Items</th>
      <td colspan="2">1</td>
    </tr>
  </tbody>
</table>



### services.name


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The unique name of the service</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.friendly_name


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The user friendly name of the service</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.tier


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The unique name of the service tier</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    <tr>
      <th>Enum</th>
      <td colspan="2"><ul><li>sv</li><li>lb</li><li>stor</li><li>db</li><li>inf</li></ul></td>
    </tr>
  </tbody>
</table>




### services.owner


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The owner of the service</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.label


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The unique label of the service. Must start with scope &#x60;Service::&#x60;</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.business


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Object</td></tr>
    
  </tbody>
</table>



### services.business.SLA


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Object</td></tr>
    
  </tbody>
</table>



### services.business.SLA.overall_sla_weighting


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The value to use as a weighted average to include the service in overall SLA</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Integer</td></tr>
    
  </tbody>
</table>






### services.technical


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Object</td></tr>
    
  </tbody>
</table>



### services.technical.project


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The list of project links for the service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>Array</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.technical.project.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    <tr>
      <th>Unique Items</th>
      <td colspan="2">true</td>
    </tr>
  </tbody>
</table>




### services.technical.project.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### services.technical.documents


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Object</td></tr>
    
  </tbody>
</table>



### services.technical.documents.design


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The link to design document for the service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.technical.documents.design.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.technical.documents.design.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### services.technical.documents.architecture


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The link to architecture document for the service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.technical.documents.architecture.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.technical.documents.architecture.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### services.technical.documents.readiness_review


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The link to production readiness review document for the service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.technical.documents.readiness_review.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.technical.documents.readiness_review.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### services.technical.documents.sre_guide


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The link to SRE guide document for the service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.technical.documents.sre_guide.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.technical.documents.sre_guide.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### services.technical.documents.developer_guide


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The link to developer guide document for the service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.technical.documents.developer_guide.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.technical.documents.developer_guide.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### services.technical.documents.service


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The list of links for the service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>Array</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.technical.documents.service.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    <tr>
      <th>Unique Items</th>
      <td colspan="2">true</td>
    </tr>
  </tbody>
</table>




### services.technical.documents.service.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### services.technical.documents.security


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The link to security document for the service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.technical.documents.security.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.technical.documents.security.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>






### services.technical.logging


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The list of logging links for the service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>Array</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.technical.logging.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    <tr>
      <th>Min Items</th>
      <td colspan="2">1</td>
    </tr>
  </tbody>
</table>



### services.technical.logging.0.name


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The name of logging link for the service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.technical.logging.0.name.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.technical.logging.0.name.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### services.technical.logging.0.permalink


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The URL of logging link for the service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.technical.logging.0.permalink.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.technical.logging.0.permalink.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>






### services.technical.logging.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### services.technical.dependencies


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">DEPRECATED: The list of dependencies for the service</td>
    </tr>
    
    
  </tbody>
</table>




### services.technical.components


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">DEPRECATED: The list of components for the service</td>
    </tr>
    
    
  </tbody>
</table>




### services.technical.sub_components


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">DEPRECATED: The list of components for the service</td>
    </tr>
    
    
  </tbody>
</table>





### services.observability


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Object</td></tr>
    
  </tbody>
</table>



### services.observability.monitors


<table>
  <tbody>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>Object</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.observability.monitors.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Object</td></tr>
    
  </tbody>
</table>



### services.observability.monitors.0.primary_grafana_dashboard


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The primary Grafana dashboard for the service. Must be relative for appending to Grafana base URL</td>
    </tr>
    
    
  </tbody>
</table>




### services.observability.monitors.0.grafana_folder


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The Grafana folder for the service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.observability.monitors.0.grafana_folder.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.observability.monitors.0.grafana_folder.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### services.observability.monitors.0.sentry_slug


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The Sentry slug for the service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.observability.monitors.0.sentry_slug.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.observability.monitors.0.sentry_slug.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### services.observability.monitors.0.gitlab_dashboard


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The GitLab dashboard for the service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.observability.monitors.0.gitlab_dashboard.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.observability.monitors.0.gitlab_dashboard.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>






### services.observability.monitors.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>





### services.observability.alerts


<table>
  <tbody>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>Array</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.observability.alerts.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    
  </tbody>
</table>



### services.observability.alerts.0.alert_link


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The link of the alert for a service</td>
    </tr>
    <tr><tr><th rowspan="2">Type</th><td rowspan="2">One of:</td><td>String</td></tr><tr><td>Null</td></tr></tr>
    
  </tbody>
</table>



### services.observability.alerts.0.alert_link.0


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    
  </tbody>
</table>




### services.observability.alerts.0.alert_link.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>






### services.observability.alerts.1


<table>
  <tbody>
    <tr><th>Type</th><td colspan="2">Null</td></tr>
    
  </tbody>
</table>






### services.teams


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">DEPRECATED: The list of the teams associated with the service</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    <tr>
      <th>Unique Items</th>
      <td colspan="2">true</td>
    </tr>
  </tbody>
</table>







## tiers


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The list of service tiers</td>
    </tr>
    <tr><th>Type</th><td colspan="2">Array</td></tr>
    <tr>
      <th>Required</th>
      <td colspan="2">No</td>
    </tr>
    <tr>
      <th>Min Items</th>
      <td colspan="2">1</td>
    </tr>
  </tbody>
</table>



### tiers.name


<table>
  <tbody>
    <tr>
      <th>Description</th>
      <td colspan="2">The unique name of the service tier</td>
    </tr>
    <tr><th>Type</th><td colspan="2">String</td></tr>
    <tr>
      <th>Enum</th>
      <td colspan="2"><ul><li>sv</li><li>lb</li><li>stor</li><li>db</li><li>inf</li></ul></td>
    </tr>
  </tbody>
</table>












