# Overview of how we have rate limits controlled for GitLab.com

## 3 layers of Rate Limiting:

#### Cloudflare

Cloudflare serves as our "outer-most" layer of protection.   We use Cloudflare's standard DDOS protection plus [Spectrum](https://www.cloudflare.com/products/cloudflare-spectrum/) to protect git over ssh.

We can also use [Cloudflare WAF or page rules](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/cloudflare/managing-traffic.md) to bluntly manage traffic when needed. 

Graphs of the Cloudflare rules can be found in dashboards at the [Cloudflare traffic overview](https://dashboards.gitlab.net/d/sPqgMv9Zk/cloudflare-traffic-overview?orgId=1&refresh=30s)

#### HAProxy

We have legacy rate limiting in HAProxy using stick tables for IP per connection and request.  
In the long run, these will be replaced by either rate limits in GitLab (below) or Cloudflare.

See related docs in [../frontend](../frontend/) for other information on blocking and haproxy config.

Graphs for HAProxy can be found at the [HAProxy page](https://dashboards.gitlab.net/d/ZOOh_aNik/haproxy?orgId=1&refresh=5m) and you can look for 429 rates to get an idea on what is being rate limited at this level, though note that some may also be coming from the application.

#### Application

[GitLab has settings](https://docs.gitlab.com/ee/security/rate_limits.html) to manage rate limits in the application.  When we plan to change these rate limits, we need to open change issues per our change control policies - https://about.gitlab.com/handbook/engineering/infrastructure/change-management/#change-request-workflows.

If a customer would like to request an exception to the standard rate limiting we have in place, there will be an issue template - `request-rate-limiting` in the [infrastructure queue](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues) to do so.

