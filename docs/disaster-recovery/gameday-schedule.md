# Disaster Recovery Gameday Schedule

The following is the schedule for gamedays in FY26 and FY27. We're assigning these in a round-robin style, so the schedule continues until every team has had an opportunity to do each Gameday. The teams are free to schedule the gameday at their convenience, but they must be completed by the end of the quarter.

## Gameday Kinds

We currently have 4 different types of gameday.

1. [Gitaly](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/disaster-recovery/recovery-measurements.md#gitaly)
2. [Patroni/pgbouncer](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/disaster-recovery/recovery-measurements.md#patronipgbouncer)
3. [HAProxy/Traffic Routing](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/disaster-recovery/recovery-measurements.md#haproxytraffic-routing-zonal-outage-dr-process-time)
4. [CI Runners](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/disaster-recovery/recovery-measurements.md#ci-runner-zonal-outage-dr-process-time)

## Included Teams

The following teams have been identified as necessary to perform gamedays and be familiar with our Disaster Recovery processes.

- [Foundations](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/foundations/)
- [Durability](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/data-access/durability/)
- [Observability](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/scalability/observability/)
- [DB Operations](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/data-access/database-operations/)
- [Runway](https://handbook.gitlab.com/handbook/engineering/infrastructure/platforms/tools/runway/)
- [Delivery: Deployments](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/delivery/#deliverydeployments)
- [Delivery: Release](https://handbook.gitlab.com/handbook/engineering/infrastructure/team/delivery/#deliveryreleases)

## FY26-Q1

| Gameday           | Team          |
| ----------------- | ------------- |
| HAproxy           | Foundations   |
| pgbouncer/patroni | Durability    |
| Gitaly            | Observability |
| CI Runners        | DB Operations |

## FY26-Q2

| Gameday           | Team                  |
| ----------------- | --------------------- |
| HAproxy           | Runway                |
| pgbouncer/patroni | Delivery: Release     |
| Gitaly            | Delivery: Deployments |
| CI Runners        | Foundations           |

## FY26-Q3

| Gameday           | Team          |
| ----------------- | ------------- |
| HAproxy           | Durability    |
| pgbouncer/patroni | Observability |
| Gitaly            | DB Operations |
| CI Runners        | Runway        |

## FY26-Q4

| Gameday           | Team                  |
| ----------------- | --------------------- |
| HAproxy           | Delivery: Release     |
| pgbouncer/patroni | Delivery: Deployments |
| Gitaly            | Foundations           |
| CI Runners        | Durability            |

## FY27-Q1

| Gameday           | Team              |
| ----------------- | ----------------- |
| HAproxy           | Observability     |
| pgbouncer/patroni | DB Operations     |
| Gitaly            | Runway            |
| CI Runners        | Delivery: Release |

## FY27-Q2

| Gameday           | Team                  |
| ----------------- | --------------------- |
| HAproxy           | Delivery: Deployments |
| pgbouncer/patroni | Foundations           |
| Gitaly            | Durability            |
| CI Runners        | Observability         |

## FY27-Q3

| Gameday           | Team                  |
| ----------------- | --------------------- |
| HAproxy           | DB Operations         |
| pgbouncer/patroni | Runway                |
| Gitaly            | Delivery: Release     |
| CI Runners        | Delivery: Deployments |
