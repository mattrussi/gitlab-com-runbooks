## GitLab Service Catalog Schema Type

`object` ([GitLab Service Catalog Schema](service-catalog.md))

# GitLab Service Catalog Schema Properties

| Property              | Type    | Required | Nullable       | Defined by                                                                                                                                                                               |
| :-------------------- | :------ | :------- | :------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [teams](#teams)       | `array` | Optional | cannot be null | [GitLab Service Catalog Schema](service-catalog-properties-teams.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/properties/teams")       |
| [services](#services) | `array` | Optional | cannot be null | [GitLab Service Catalog Schema](service-catalog-properties-services.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/properties/services") |
| [tiers](#tiers)       | `array` | Optional | cannot be null | [GitLab Service Catalog Schema](service-catalog-properties-tiers.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/properties/tiers")       |

## teams

The list of teams

`teams`

*   is optional

*   Type: `object[]` ([Details](service-catalog-properties-teams-items.md))

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-properties-teams.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/properties/teams")

### teams Type

`object[]` ([Details](service-catalog-properties-teams-items.md))

### teams Constraints

**minimum number of items**: the minimum number of items for this array is: `1`

## services

The list of services

`services`

*   is optional

*   Type: `object[]` ([Details](service-catalog-properties-services-items.md))

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-properties-services.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/properties/services")

### services Type

`object[]` ([Details](service-catalog-properties-services-items.md))

### services Constraints

**minimum number of items**: the minimum number of items for this array is: `1`

## tiers

The list of service tiers

`tiers`

*   is optional

*   Type: `object[]` ([Details](service-catalog-properties-tiers-items.md))

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-properties-tiers.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/properties/tiers")

### tiers Type

`object[]` ([Details](service-catalog-properties-tiers-items.md))

### tiers Constraints

**minimum number of items**: the minimum number of items for this array is: `1`

# GitLab Service Catalog Schema Definitions

## Definitions group TeamDefinition

Reference this group by using

```json
{"$ref":"https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition"}
```

| Property                                                                              | Type      | Required | Nullable       | Defined by                                                                                                                                                                                                                                                                                               |
| :------------------------------------------------------------------------------------ | :-------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [name](#name)                                                                         | `string`  | Required | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-name.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/name")                                                                   |
| [url](#url)                                                                           | `string`  | Optional | can be null    | [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-url.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/url")                                                                     |
| [product\_stage\_group](#product_stage_group)                                         | `string`  | Optional | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-product_stage_group.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/product_stage_group")                                     |
| [slack\_alerts\_channel](#slack_alerts_channel)                                       | `string`  | Optional | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-slack_alerts_channel.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/slack_alerts_channel")                                   |
| [send\_slo\_alerts\_to\_team\_slack\_channel](#send_slo_alerts_to_team_slack_channel) | `boolean` | Optional | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-send_slo_alerts_to_team_slack_channel.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/send_slo_alerts_to_team_slack_channel") |
| [alerts](#alerts)                                                                     | `array`   | Optional | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-alerts.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/alerts")                                                               |
| [ignored\_components](#ignored_components)                                            | `array`   | Optional | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-ignored_components.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/ignored_components")                                       |
| [slack\_error\_budget\_channel](#slack_error_budget_channel)                          | Merged    | Optional | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-slack_error_budget_channel.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/slack_error_budget_channel")                       |
| [send\_error\_budget\_weekly\_to\_slack](#send_error_budget_weekly_to_slack)          | `boolean` | Optional | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-send_error_budget_weekly_to_slack.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/send_error_budget_weekly_to_slack")         |
| [manager\_slug](#manager_slug)                                                        | `string`  | Optional | can be null    | [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-manager_slug.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/manager_slug")                                                   |
| [engagement\_policy](#engagement_policy)                                              | `string`  | Optional | can be null    | [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-engagement_policy.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/engagement_policy")                                         |
| [oncall\_schedule](#oncall_schedule)                                                  | `string`  | Optional | can be null    | [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-oncall_schedule.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/oncall_schedule")                                             |
| [slack\_channel](#slack_channel)                                                      | `string`  | Optional | can be null    | [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-slack_channel.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/slack_channel")                                                 |

### name

The unique name of the team

`name`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-name.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/name")

#### name Type

`string`

### url

The handbook URL of the team

`url`

*   is optional

*   Type: `string`

*   can be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-url.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/url")

#### url Type

`string`

### product\_stage\_group

The product stage group of the team. Must match `group` key in <https://gitlab.com/gitlab-com/www-gitlab-com/-/blob/master/data/stages.yml>

`product_stage_group`

*   is optional

*   Type: `string`

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-product_stage_group.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/product_stage_group")

#### product\_stage\_group Type

`string`

### slack\_alerts\_channel

The name of the Slack channel to receive alerts for the team. Must omit `#` prefix

`slack_alerts_channel`

*   is optional

*   Type: `string`

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-slack_alerts_channel.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/slack_alerts_channel")

#### slack\_alerts\_channel Type

`string`

#### slack\_alerts\_channel Constraints

**pattern**: the string must match the following regular expression:&#x20;

```regexp
^(?!#.*$).*
```

[try pattern](https://regexr.com/?expression=%5E\(%3F!%23.*%24\).* "try regular expression with regexr.com")

### send\_slo\_alerts\_to\_team\_slack\_channel

The setting to enable/disable receiving alerts in the team's Slack alert channel

`send_slo_alerts_to_team_slack_channel`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-send_slo_alerts_to_team_slack_channel.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/send_slo_alerts_to_team_slack_channel")

#### send\_slo\_alerts\_to\_team\_slack\_channel Type

`boolean`

### alerts

The list of environments for alerts for the team introduced in <https://gitlab.com/gitlab-com/runbooks/-/merge_requests/5176>

`alerts`

*   is optional

*   Type: `string[]`

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-alerts.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/alerts")

#### alerts Type

`string[]`

#### alerts Constraints

**unique items**: all items in this array must be unique. Duplicates are not allowed.

### ignored\_components

The list of components that should not feed into the team's error budget

`ignored_components`

*   is optional

*   Type: `string[]`

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-ignored_components.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/ignored_components")

#### ignored\_components Type

`string[]`

#### ignored\_components Constraints

**unique items**: all items in this array must be unique. Duplicates are not allowed.

### slack\_error\_budget\_channel

The name of the Slack channel to receive weekly error budget reports for the team. Must omit `#` prefix

`slack_error_budget_channel`

*   is optional

*   Type: merged type ([Details](service-catalog-definitions-teamdefinition-properties-slack_error_budget_channel.md))

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-slack_error_budget_channel.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/slack_error_budget_channel")

#### slack\_error\_budget\_channel Type

merged type ([Details](service-catalog-definitions-teamdefinition-properties-slack_error_budget_channel.md))

any of

*   [Untitled array in GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-slack_error_budget_channel-anyof-0.md "check type definition")

*   [Untitled string in GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-slack_error_budget_channel-anyof-1.md "check type definition")

### send\_error\_budget\_weekly\_to\_slack

The setting to enable/disable receiving weekly error budget reports in the team's Slack error budget channel

`send_error_budget_weekly_to_slack`

*   is optional

*   Type: `boolean`

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-send_error_budget_weekly_to_slack.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/send_error_budget_weekly_to_slack")

#### send\_error\_budget\_weekly\_to\_slack Type

`boolean`

### manager\_slug

DEPRECATED: The manager's slug for the team

`manager_slug`

*   is optional

*   Type: `string`

*   can be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-manager_slug.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/manager_slug")

#### manager\_slug Type

`string`

### engagement\_policy

DEPRECATED: The engagement policy of the team

`engagement_policy`

*   is optional

*   Type: `string`

*   can be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-engagement_policy.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/engagement_policy")

#### engagement\_policy Type

`string`

### oncall\_schedule

DEPRECATED: The on-call schedule of the team

`oncall_schedule`

*   is optional

*   Type: `string`

*   can be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-oncall_schedule.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/oncall_schedule")

#### oncall\_schedule Type

`string`

### slack\_channel

DEPRECATED: The Slack channel of the team

`slack_channel`

*   is optional

*   Type: `string`

*   can be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-teamdefinition-properties-slack_channel.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TeamDefinition/properties/slack_channel")

#### slack\_channel Type

`string`

## Definitions group ServiceDefinition

Reference this group by using

```json
{"$ref":"https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition"}
```

| Property                         | Type     | Required | Nullable       | Defined by                                                                                                                                                                                                                                                     |
| :------------------------------- | :------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [name](#name-1)                  | `string` | Required | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-name.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/name")                   |
| [friendly\_name](#friendly_name) | `string` | Required | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-friendly_name.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/friendly_name") |
| [tier](#tier)                    | `string` | Required | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-tier.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/tier")                   |
| [owner](#owner)                  | `string` | Required | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-owner.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/owner")                 |
| [label](#label)                  | `string` | Required | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-label.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/label")                 |
| [business](#business)            | `object` | Optional | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-business.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/business")           |
| [technical](#technical)          | `object` | Optional | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-technical.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/technical")         |
| [observability](#observability)  | `object` | Optional | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-observability.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/observability") |
| [teams](#teams-1)                | `array`  | Optional | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-teams.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/teams")                 |

### name

The unique name of the service

`name`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-name.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/name")

#### name Type

`string`

### friendly\_name

The user friendly name of the service

`friendly_name`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-friendly_name.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/friendly_name")

#### friendly\_name Type

`string`

### tier

The unique name of the service tier

`tier`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-tier.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/tier")

#### tier Type

`string`

#### tier Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value    | Explanation |
| :------- | :---------- |
| `"sv"`   |             |
| `"lb"`   |             |
| `"stor"` |             |
| `"db"`   |             |
| `"inf"`  |             |

### owner

The owner of the service

`owner`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-owner.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/owner")

#### owner Type

`string`

### label

The unique label of the service. Must start with scope `Service::`

`label`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-label.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/label")

#### label Type

`string`

### business



`business`

*   is optional

*   Type: `object` ([Details](service-catalog-definitions-servicedefinition-properties-business.md))

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-business.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/business")

#### business Type

`object` ([Details](service-catalog-definitions-servicedefinition-properties-business.md))

### technical



`technical`

*   is optional

*   Type: `object` ([Details](service-catalog-definitions-servicedefinition-properties-technical.md))

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-technical.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/technical")

#### technical Type

`object` ([Details](service-catalog-definitions-servicedefinition-properties-technical.md))

### observability



`observability`

*   is optional

*   Type: `object` ([Details](service-catalog-definitions-servicedefinition-properties-observability.md))

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-observability.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/observability")

#### observability Type

`object` ([Details](service-catalog-definitions-servicedefinition-properties-observability.md))

### teams

DEPRECATED: The list of the teams associated with the service

`teams`

*   is optional

*   Type: `string[]`

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-servicedefinition-properties-teams.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/ServiceDefinition/properties/teams")

#### teams Type

`string[]`

#### teams Constraints

**unique items**: all items in this array must be unique. Duplicates are not allowed.

## Definitions group TierDefinition

Reference this group by using

```json
{"$ref":"https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TierDefinition"}
```

| Property        | Type     | Required | Nullable       | Defined by                                                                                                                                                                                                                             |
| :-------------- | :------- | :------- | :------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [name](#name-2) | `string` | Required | cannot be null | [GitLab Service Catalog Schema](service-catalog-definitions-tierdefinition-properties-name.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TierDefinition/properties/name") |

### name

The unique name of the service tier

`name`

*   is required

*   Type: `string`

*   cannot be null

*   defined in: [GitLab Service Catalog Schema](service-catalog-definitions-tierdefinition-properties-name.md "https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TierDefinition/properties/name")

#### name Type

`string`

#### name Constraints

**enum**: the value of this property must be equal to one of the following values:

| Value    | Explanation |
| :------- | :---------- |
| `"sv"`   |             |
| `"lb"`   |             |
| `"stor"` |             |
| `"db"`   |             |
| `"inf"`  |             |

## Definitions group TierEnumDefinition

Reference this group by using

```json
{"$ref":"https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json#/definitions/TierEnumDefinition"}
```

| Property | Type | Required | Nullable | Defined by |
| :------- | :--- | :------- | :------- | :--------- |
