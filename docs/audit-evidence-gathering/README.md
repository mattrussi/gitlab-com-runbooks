## Runbook for audit evidence gathering procedures

#### Gathering the list of Chef Admins / users

1. ssh to the chef server
2. Chef admins: These are effectively people who have sudo on the chef- server `sudo getent group production`
3. Should you need to get a list of the chef users (people with access to interact with knife)
`for u in $(sudo chef-server-ctl user-list); do sudo chef-server-ctl user-show $u |head -n 2|sed 's/display_name://g' |sed 's/email://g'|paste -sd "," -; done`

4. chef-repo project admins:  `https://ops.gitlab.net/api/v4/projects/139/members/all?sort=access_level_desc&per_page=200` and parse for users who are level 40 or above per https://docs.gitlab.com/ee/api/members.html

#### Gathering the list of people with production access

clone down chef repo
Rails console: `ruby bin\prod_access_report.rb -a rails-console`
DB console: `ruby bin\prod_access_report.rb -a db-console`

### GCP access to gitlab-production
from the command line with gcloud installed:
1. `gcloud beta identity groups memberships list --group-email="gcp-ops-sg@gitlab.com" |grep id|sed 's/id://g'`
2. `gcloud beta identity groups memberships list --group-email="gcp-owners-sg@gitlab.com" |grep id|sed 's/id://g'` 

### Production Server list (Server lists for Bastions, Production Servers, Database servers)

Clone down chef repo and:
Find the right roles for the 3 above categories.
Run the commands:
- $ knife search node role:gprd-base-bastion -i
- $ knife search node roles:gprd-base -i
- $ knife search node 'roles:gprd-base-db-postgres OR roles:gprd-base-db-patroni' -i
