[[_TOC_]]

# Summary

`Wiz Runtime Sensor`` is a small ebpf (Extended Berkeley Packet Filter) agent deployed on every Kubernetes Node, meticulously monitoring system calls to pinpoint suspicious activities. It proactively identifies and alerts on behaviors that look malicious, signaling potential security threats or anomalies. The Wiz Sensor operates by leveraging a set of rules that define which system call sequences and activities are deemed abnormal or indicative of security incidents.

# Monitoring/Alerting

# Troubleshooting

# Links to further Documentation

* [Wiz Helm Chart](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-helmfiles/-/tree/master/releases/wiz-sensor)
* [Internal Handbook Page](https://internal.gitlab.com/handbook/security/infrastructure_security/tooling/wiz-sensor/)
