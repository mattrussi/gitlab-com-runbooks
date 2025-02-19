local metricsCatalog = import 'servicemetrics/metrics.libsonnet';

local rateMetric = metricsCatalog.rateMetric;
local errorCounterApdex = metricsCatalog.errorCounterApdex;
local histogramApdex = metricsCatalog.histogramApdex;

local baseSelector = {
    job: "hosted-runners-fluentd-agent",
    shard: { re: '.*' },
    plugin: 's3'
};

metricsCatalog.serviceDefinition({
    type: 'hosted-runners-logging',
    tier: 'inf',

    serviceIsStageless: true,
    regional: false,

    shardLevelMonitoring: true,
    disableOpsRatePrediction: false,
    shard: [],

    provisioning: {
        // Set it to false for now as we do not have node metrics.
        vms: false,
        kubernetes: false,
    },

    monitoringThresholds: {
        errorRatio: 0.999,
    },

    serviceLevelIndicators:{
        usage_logs: { 
            userImpacting: false,
            featureCategory: 'not_owned',
            severity: 's1',
            serviceAggregation: false,
            shardLevelMonitoring: true,
            description: |||
                This log SLI represents the total number of errors encountered by Fluentd while writing
                logs to S3 destination.
            |||,

            requestRate: rateMetric(
                counter='fluentd_output_status_write_count',
                selector=baseSelector,
            ),
            
            errorRate: rateMetric(
                counter='fluentd_output_status_num_errors',
                selector=baseSelector,
            ),

            significantLabels: [],
        }
    }
})