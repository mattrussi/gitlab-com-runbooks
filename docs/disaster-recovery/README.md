## Summary

This contains the relevant information for Disaster Recovery on GitLab.com as it relates to testing, validation, and current gaps that would prevent recovery.

### Recovery from a zonal outage

The Reliability team validates the ability recovery from a disaster that impacts a single availability zone.

GitLab.com is deployed in single region, [us-east1 in GCP](https://about.gitlab.com/handbook/engineering/infrastructure/production/architecture/), a regional outage is not currently in scope for Infrastructure disaster recovery validation; for more information, see the [discovery issue for regional recovery](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/16250).

### Testing

A helper script is available to help simulate a zonal outage by setting up firewall rules that prevent both ingress and egress traffic, currently this is available to run in our non-prod environments for the zones `us-east1-b` and `us-east1-d`.
The zone `us-east1-c` has [SPOFs like the deploy and console nodes](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/16251#us-east1-c-outage) so we should avoid running tests on this zone until they have been resolved in the [epic tracking critical work related to zonal failures](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/800).

#### Setting firewall rules

**Note**: Run this script with care! All changes should go through [change management](https://about.gitlab.com/handbook/engineering/infrastructure/change-management/), even for non-prod environments!

```
$ ./zone-denier -h
Usage: ./zone-denier [-e <environment> (gstg|pre) -a <action> (deny|allow) -z <zone> -d]

  -e : Environment to target, must be a non-prod env
  -a : deny or allow traffic for the specified zone
  -z : availability zone to target
  -d (optional): run in dry-run mode

Examples:

  # Use the dry-run option to see what infra will be denied
  ./zone-denier -e pre -z us-east1-b -a deny -d

  # Deny both ingress and egress traffic in us-east1-b in PreProd
  ./zone-denier -e pre -z us-east1-b -a deny

  # Revert the deny to allow traffic
  ./zone-denier -e pre -z us-east1-b -a allow
```

The script is configured to exclude a static list of known SPOFs for each environment.
