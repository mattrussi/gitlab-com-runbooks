## Runbook for audit evidence gathering procedures

#### Gathering the list of Chef Admins / users

1. ssh to the chef server
2. Chef admins: These are effectively people who have sudo on the chef- server `sudo getent group production`
3. Should you need to get a list of the chef users (people with access to interact with knife)
`for u in $(sudo chef-server-ctl user-list); do sudo chef-server-ctl user-show $u |head -n 2|sed 's/display_name://g' |sed 's/email://g'|paste -sd "," -; done`

#### Gathering the list of people with production access

clone down chef repo
Rails console: `ruby bin\prod_access_report.rb -a rails-console`
DB console: `ruby bin\prod_access_report.rb -a db-console`

### GCP access to gitlab-production

