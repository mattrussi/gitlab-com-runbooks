# Tuning and Modifying Alerts

Our metrics, notification rules, Pagerduty and Slack are all configurable to help engineers be aware of the status of our environments.

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

### Selectors

Selectors can allow a metric to exclude or include metric labels.

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
