local alerts = import 'alerts/alerts.libsonnet';

local DaemonSetAlerts(name, labels) = [
        {
            alert: 'KubeDaemonSetRolloutStuck',
            expr: |||
                (
                    kube_daemonset_status_number_ready{job="kube-state-metrics", daemonset="%(name)s"}
                    /
                    kube_daemonset_status_desired_number{job="kube-state-metrics, daemonset="%(name)s"} * 100 < 100
                )
            ||| % { name: name },
            'for': '15m',
            labels: labels,
            annotations: {
                title: 'Daemonset Rollout is incomplete.',
                description: 'Only {{ $value }} of the desired Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are scheduled and ready.',
                runbook: "docs/uncategorized/kubernetes.md",
            },
        },
        {
            alert: 'KubeDaemonSetNotScheduled',
            expr: |||
                (
                    kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics", daemonset="%(name)s"}
                    -
                    kube_daemonset_status_current_number_scheduled{job="kube-state-metrics", daemonset="%(name)s"} > 0
                )
            ||| % { name: name },
            'for': '15m',
            labels: labels,
            annotations: {
                title: 'DaemonSet Pod(s) unable to be scheduled',
                description: '{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are not scheduled.',
                runbook: 'docs/uncategorized/kubernetes.md',
            },
        },
        {
            alert: 'KubeDaemonSetMisScheduled',
            expr: 'kube_daemonset_status_number_misscheduled{job="kube-state-metrics", daemonset="%(name)s"} > 0' % { name: name },
            'for': '15m',
            labels: labels,
            annotations: {
                title: 'DaemonSet Pod(s) unable to be scheduled',
                description: '{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are running where they are not supposed to run.',
                runbook: 'docs/uncategorized/kubernetes.md',
            },
        },
];

{
    'daemonset-alerts.yml': std.manifestYamlDoc({
        // Create a group for each set of labels ish
        // here ive got an example for a page and a 'ticket'
        groups: [
            {
                name: 'daemonset_alerts.yaml',
                partial_response_strategy: 'warn',
                rules: [
                    DaemonSetAlerts(ds, {
                    pager: 'pagerduty',
                    severity: 's2',
                    alert_type: 'cause'
                }) for ds in ["calico-node"]],
            },
            {
                name: 'daemonset_alerts_nonurgent.yaml',
                partial_response_strategy: 'warn',
                rules: [
                    DaemonSetAlerts(ds, {
                    severity: 's3',
                    alert_type: 'cause',
                }) for ds in ["fluentd"]]
            }
        ]
    }),
}

