# Blocking individual IPs and Net Blocks on HA Proxy

**Table of Contents**

[TOC]

## First and Foremost

- **Don't Panic!**
- Be careful when manipulating the ip blacklist.

## Background

From time to time it may become necessary to block IP addresses or networks of IP addresses from accessing GitLab.
We now generally use Cloudflare for that, but as of now GitLab Pages and Registry are not behind Cloudflare. There are also situations where Cloudflare simply doesn't offer functionality we need, for example if we need to block SSH traffic from certain locales, but not an entire country.
In this case we can still use the old way by managing those IP addresses in the file
[deny-403-ips.lst](https://gitlab.com/gitlab-com/security-tools/front-end-security/blob/master/deny-403-ips.lst) in the
[security-tools/front-end](https://gitlab.com/gitlab-com/security-tools/front-end-security) repository. Updates to this file
are distributed to the HA Proxy nodes on each chef run by the [gitlab-haproxy](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy) cookbook.

**Even if it's called `deny-403-ips.lst` - it will also block non-HTTP traffic!**

**The gitlab.com repo is mirrored by the <https://ops.gitlab.net/infrastructure/lib/front-end-security/> instance and the `gitlab-haproxy` role is picking up changes from there!**

## How do I

### See what IP addresses are currently blocked

Open [deny-403-ips.lst](https://gitlab.com/gitlab-com/security-tools/front-end-security/blob/master/deny-403-ips.lst).

Or, on a haproxy node, look into `/etc/haproxy/front-end-security/deny-403-ips.lst`.

### Add a netblock to the list

Just like Santa Clause, you want to check your list twice before you sort the naughties into the blackhole.

- Edit and commit [deny-403-ips.lst](https://gitlab.com/gitlab-com/security-tools/front-end-security/blob/master/deny-403-ips.lst).
  - All IP addresses must have a subnet mask, even if it's a single address (/32).
  - There are also automations (e.g. [`geoblockr`](https://gitlab.com/gitlab-com/gl-infra/geoblockr)) adding to/removing from the list, so take special note of any comments in the file.
- Wait for changes to be mirrored to the ops.gitlab.net instance and for the next chef run to pick them up and reload haproxy on the LBs.

How can we make this go faster?

- Manually force the mirror sync in the [repo settings](https://ops.gitlab.net/infrastructure/lib/front-end-security/settings/repository)
- run chef client on the haproxy nodes:

```
knife ssh 'roles:gprd-base-lb' sudo chef-client
```

### Remove a netblock from the list

Same as above.

## CLEAN UP

It is important to note that blackhole entries ***DO NOT*** clean up after themselves,
you must remove the entries after the threat or issue has been mitigated / resolved.
When a network is blackholed the users are not able to reach ANY of the GitLab infrastructure
that depends upon the HA Proxies (almost all of it!).
This makes it even more important that you clean up after yourself.
You will probably want to work together with the abuse team and support.
