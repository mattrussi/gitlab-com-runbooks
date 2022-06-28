# Tuning and Modifying Alerts

Our metrics and notification systems are all configurable to help engineers be aware of the status of our environments. When you are creating, removing, or changing notification parameters, keep these questions in mind:

1. Who needs to see this notification?
2. What actions are expected of the recipient of this notification?
3. What level of immediacy is required to this notification?
4. Is this notification a strong indicator of a problem, or just a likely indicator that something may be wrong?

## Other Notification Management Resources

- [An impatient SRE's guide to deleting alerts](./deleting-alerts.md)
- [Apdex alerts troubleshooting](./apdex-alerts-guide.md)
- [Alerting Manual](./alerts_manual.md)

## Service Catalog

The [service catalog](../../services/README.md) contains team definitions and service definitions.

## Metrics Catalog

The [metrics catalog](../../metrics-catalog/README.md) is where services and their service level idicators can be changed.

## Tuning Notifications

There are many reasons to alter the existing configuration for notifications:
    - Too many false positive notifications
    - Un-actionable notifications
    - The notifcation is not a real problem

These configurations should be reviewed often and updated when neccessary. The following sections mostly describe the values you can look to for tuning notifications derived from the metrics catalog. The [metrics catalog README](../../metrics-catalog/README.md) has a good breakdown of the structure of a service definition for these parameters below.

### Severity

SLI components can have a specific severity defined. Sometimes the alert is important enough to go to Slack (Sev 3 or 4), but not important enough to require notifying an on-call in via page (Sev 1 or 2). Below is a snippet of an SLI that is set to appear as a Slack notification, but not page.

```
serviceLevelIndicators: {
    sentry_events: {
      severity: 's3',
      userImpacting: false,
```

### Selectors

SLI component selectors can allow a metric to exclude or include metric labels.

For example, this selector definition for the frontend service excludes canary, websockets, and api_rate_limit backends from the apdex.

```
selector='type="frontend", backend_name!~"canary_.*|api_rate_limit|websockets"'
```

### Thresholds

For an Apdex, the [tolerated and satisfied thresholds](./definition-service-apdex.md) can be changed to better match the expected latency of service requests.

### ApdexScore

Modifying the monitoringThresholds apdexScore value will alter the Apdex threshold for the service as a whole.

### ErrorRatio

This is similar to the apdexScore but is a value for how many errors are tolerated for the service as a whole.

## Removing Notifications

It is also quite reasonable to consider removing metrics, stopping notifications, or lowering their severity.