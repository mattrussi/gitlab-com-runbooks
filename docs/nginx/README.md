<!-- MARKER: do not edit this section directly. Edit services/service-catalog.yml then run scripts/generate-docs -->

**Table of Contents**

[[_TOC_]]

#  Nginx Service
* **Alerts**: https://alerts.gitlab.net/#/alerts?filter=%7Btype%3D%22nginx%22%2C%20tier%3D%22sv%22%7D
* **Label**: gitlab-com/gl-infra/production~"Service:NGINX"

## Logging

* [Kubernetes](https://log.gprd.gitlab.net/goto/88eab835042a07b213b8c7f24213d5bf)
* [Error Logs](https://cloudlogging.app.goo.gl/neeqq5jQEKWsxZRx8)

## Troubleshooting Pointers

* [../forum/discourse-forum.md](../forum/discourse-forum.md)
* [../frontend/haproxy.md](../frontend/haproxy.md)
* [../license/license-gitlab-com.md](../license/license-gitlab-com.md)
* [../monitoring/definition-service-error-rate.md](../monitoring/definition-service-error-rate.md)
* [../monitoring/definition-service-ops-rate.md](../monitoring/definition-service-ops-rate.md)
* [../monitoring/filesystem_alerts.md](../monitoring/filesystem_alerts.md)
* [../monitoring/monitor-gitlab-net-not-accessible.md](../monitoring/monitor-gitlab-net-not-accessible.md)
* [../onboarding/gitlab.com_on_k8s.md](../onboarding/gitlab.com_on_k8s.md)
* [../sentry/sentry-is-down.md](../sentry/sentry-is-down.md)
* [../tutorials/overview_life_of_a_git_request.md](../tutorials/overview_life_of_a_git_request.md)
* [../tutorials/overview_life_of_a_web_request.md](../tutorials/overview_life_of_a_web_request.md)
* [../uncategorized/about-gitlab-com.md](../uncategorized/about-gitlab-com.md)
* [../uncategorized/manage-chef.md](../uncategorized/manage-chef.md)
* [../uncategorized/mtail.md](../uncategorized/mtail.md)
* [../uncategorized/namespace-restore.md](../uncategorized/namespace-restore.md)
* [../uncategorized/packagecloud-infrastructure.md](../uncategorized/packagecloud-infrastructure.md)
* [../uncategorized/setup-oauth2-proxy-protected-application.md](../uncategorized/setup-oauth2-proxy-protected-application.md)
* [../version/version-gitlab-com.md](../version/version-gitlab-com.md)
* [../web/nginx-is-down.md](../web/nginx-is-down.md)
<!-- END_MARKER -->

## Summary

NGINX sits in front of our Puma services.  It provides a bit of protection
between end users and puma workers to prevent saturation of threads.

## Architecture

For Virtual Machines, this is deployed via our Omnibus package and runs as a
service that recieves traffic.

For Kubernetes, this is deployed using the NGINX Ingress controller managed by
our helm chart.  https://docs.gitlab.com/charts/charts/nginx/

### Configuration

https://docs.gitlab.com/omnibus/settings/nginx.html

<!-- ## Performance -->

<!-- ## Scalability -->

<!-- ## Availability -->

<!-- ## Durability -->

<!-- ## Security/Compliance -->

<!-- ## Monitoring/Alerting -->

<!-- ## Links to further Documentation -->
