Sometimes it may be helpful to ssh into one of the transient runner VMs managed by our runner-managers, to debug an incident or other issue.  

From the GitLab.com web UI, find:
* the runner-manager hostname (example: shared-runners-manager-5.gitlab.com) from the top section of the right sidebar
* the ephemeral runner name (in the output, under "Preparing environment" is "Running on runner-XXXX")

From and ssh session on the identified runner-manager host
```
$ sudo -i docker-machine ssh $RUNNER_VM
```

If the ephemeral runner VM name cannot be found in the job output, the job id (e.g. 705346984) and logs can be used to find it.  From an ssh session on the runner-manager host:

$ JOB_ID=705346984
$ RUNNER_VM=$(sudo cat /var/log/syslog | grep 'gitlab-runner' | grep -w "$JOB_ID" | perl -pe 's/.*?gitlab-runner\[\d+\]:\s*//'|jq 'select(.name) | .name' | tr -d '"'|head -n 1)
$ sudo -i docker-machine ssh $RUNNER_VM

## Side note 
`sudo -i` (or `sudo su -`) is necessary to get the full root login experience for docker-machine to run correctly; without the `-i`, it will claim the machine doesn't exist.
