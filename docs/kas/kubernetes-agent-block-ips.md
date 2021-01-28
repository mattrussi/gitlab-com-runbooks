# Kubernetes-Agent Block IPs
In the event that we need to block specific IPs from hitting the Kubernetes agent endpoint, we
have a [Google Cloud Armor Policy](https://cloud.google.com/armor/docs/security-policy-concepts)
attacked to the GKE Ingress that KAS uses. Currently there is only one rule in that policy, which
is the default rule to allow all traffic.

If you need to block a particular IP from accessing KAS, find the `google_compute_security_policy`
terraform resource called `kas-ingress-policy` (inside the `gke-regional.tf` file) and add a
rule similar to the following.

```
/* The following is an example rule to block IP 9.9.9.9 */
  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["9.9.9.9/32"]
      }
    }
    description = "Deny access to IPs in 9.9.9.9/32"
  }
```

This can go right above the default rule. We can use our standard terraform MR/merge/apply workflow
to apply this.

It's worth noting that cloud armor actually provides us with a few different mechanisms for matching
traffic to block/allow, as described [here](https://cloud.google.com/armor/docs/rules-language-reference).

If for example, you wished to block traffic based off the HTTP Header `User-Agent` being set to `badUser`,
you could use terraform similar to

```
/* The following is an example rule to block User-Agent badUser */
  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      expr {
        expression = "has(request.headers['User-Agent']) && request.headers['User-Agent'].contains('badUser')"
      }
    }
    description = "Deny access to User-Agent badUser"
  }
```
