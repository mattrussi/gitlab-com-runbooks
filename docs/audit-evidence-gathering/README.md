## Runbook for audit evidence gathering procedures

#### Gathering the list of Chef Admins / users

1. ssh to the chef server
2. Chef admins: These are effectively people who have sudo on the chef- server `sudo getent group production`
3. Should you need to get a list of the chef users (people with access to interact with knife)
`for u in $(sudo chef-server-ctl user-list); do sudo chef-server-ctl user-show $u |head -n 2|sed 's/display_name://g' |sed 's/email://g'|paste -sd "," -; done`

4. chef-repo project admins:  `https://ops.gitlab.net/api/v4/projects/139/members/all?sort=access_level_desc&per_page=200` and parse for users who are level 40 or above per https://docs.gitlab.com/ee/api/members.html

#### Gathering the list of people with production access

clone down [chef repo](https://ops.gitlab.net/gitlab-cookbooks/chef-repo)
Rails console: `ruby bin/prod_access_report.rb -a rails-console`
DB console: `ruby bin/prod_access_report.rb -a db-console`

### GCP access to gitlab-production
from the command line with gcloud installed:
1. `gcloud beta identity groups memberships list --group-email="gcp-ops-sg@gitlab.com" |grep id|sed 's/id://g'`
2. `gcloud beta identity groups memberships list --group-email="gcp-owners-sg@gitlab.com" |grep id|sed 's/id://g'` 

### Production Server list (Server lists for bastions, production servers, database servers)

Clone down [chef repo](https://ops.gitlab.net/gitlab-cookbooks/chef-repo) and:
Find the right roles for the 3 above categories.
Run the commands:
- $ knife search node role:gprd-base-bastion -i
- $ knife search node roles:gprd-base -i
- $ knife search node 'roles:gprd-base-db-postgres OR roles:gprd-base-db-patroni' -i

Updates based on the [definition of production](https://gitlab.com/gitlab-com/gl-security/security-assurance/sec-compliance/compliance/-/blob/master/production_definition.md) for how to list machines (compute) that meet this definition:

GitLab.com:
- `gcloud config set project gitlab-ops && gcloud compute instances list`
- `gcloud config set project gitlab-production && gcloud compute instances list` 
- `gcloud config set project gemnasium-production && gcloud compute instances list`

CI:
- `gcloud config set project gitlab-ci-155816 && gcloud compute instances list --filter="name~'manager'"`
- `gcloud config set project gitlab-org-ci-0d24e2 && gcloud compute instances list --filter="name~'manager'"`
- `gcloud config set project gitlab-ci-plan-free-7-7fe256 && gcloud compute instances list --filter="name~'manager'"`
- `gcloud config set project gitlab-ci-windows && gcloud compute instances list --filter="name~'manager'"`

License, Version:
- `gcloud config set project gs-production-efd5e8 && gcloud compute instances list` #home of version.gitlab.com
- `gcloud config set project license-prd-bfe85b && gcloud compute instances list`   #home of license.gitlab.com

dev.gitlab.org and customers.gitlab.com:
- as of 2021-03-18, still in Azure as single VMs, get IP/VM information from the Azure portal
