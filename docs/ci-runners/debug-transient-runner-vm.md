## How to SSH to an ephemeral runner VM

Sometimes it may be helpful to ssh into one of the transient runner VMs managed by our runner-managers, to debug an incident or other issue.  

From the GitLab.com web UI, find:
* the runner-manager hostname (example: shared-runners-manager-5.gitlab.com) from the top section of the right sidebar
* the ephemeral runner name (in the output, under "Preparing environment" is "Running on runner-XXXX")

From and ssh session on the identified runner-manager host
```
$ sudo -i docker-machine ssh $RUNNER_VM
```

If the ephemeral runner VM name cannot be found in the job output, the job id (e.g. 705346984) and logs can be used to find it.  From an ssh session on the runner-manager host:

```
$ JOB_ID=705346984
$ RUNNER_VM=$( sudo cat /var/log/syslog | grep 'gitlab-runner' | grep -w "$JOB_ID" | perl -pe 's/.*?gitlab-runner\[\d+\]:\s*//' | jq -r 'select(.name) | .name' | head -n 1 )
$ sudo -i docker-machine ssh $RUNNER_VM
```

### Side note 

`sudo -i` (or `sudo su -`) is necessary to get the full root login experience for docker-machine to run correctly; without the `-i`, it will claim the machine doesn't exist.  The inventory of docker machines is stored in `$HOME/.docker/machine`, and without adding `-i` to `sudo`, the `HOME` environment variable will remain set to your user's home dir (`~/`) rather than root's home dir (`/root`):

```
$ sudo env | grep HOME
HOME=/home/msmiley

$ sudo -i env | grep HOME
HOME=/root

$ sudo ls -l /root/.docker/machine/machines | wc -l
340
```

## List existing runner VMs

Although `docker-machine` provides an `ls` subcommand, it is both slow and prone to failing due to exceeding the max open files for your shell when there are too many VMs to list.

An faster and failure-free alternative is to just use `sudo ls` on the directory that holds the inventory of docker-machine-managed VMs:

```
msmiley@shared-runners-manager-5.gitlab.com:~$ sudo ls -l /root/.docker/machine/machines | head -n 3
total 1256
drwx------ 2 root root 4096 Aug 26 04:09 runner-0277ea0f-srm-1598414909-7755a300
drwx------ 2 root root 4096 Aug 26 04:09 runner-0277ea0f-srm-1598414909-859d6b7c

msmiley@shared-runners-manager-5.gitlab.com:~$ sudo -i docker-machine ls | head -n 3
NAME                                      ACTIVE   DRIVER      STATE     URL                      SWARM   DOCKER        ERRORS
runner-0277ea0f-srm-1598414909-859d6b7c   -        google      Running   tcp://10.0.44.162:2376           v18.06.3-ce   
runner-0277ea0f-srm-1598414909-7755a300   -        google      Running   tcp://10.0.35.66:2376            v18.06.3-ce   
```


## View runner-manager logs for a specific job

The `gitlab-runner` daemon (i.e. the runner manager) emits structured log events, which are available via syslog.
One way to view them from the runner-manager host is to strip the generic syslog prefix and pass the single-line JSON
to `jq`, as follows:

```
$ sudo cat /var/log/syslog | grep 'gitlab-runner' | grep -w "$JOB_ID" | perl -pe 's/.*?gitlab-runner\[\d+\]:\s*//' | jq .
```

These log events often include other useful searchable fields, such as job id, project id, runner VM name, and runner VM private IP.
For example, the following log event shows a job being assigned to a runner VM.

```
{
  "created": "2020-08-26T18:27:26.253434556Z",
  "docker": "tcp://10.0.39.133:2376",
  "job": 705346984,
  "level": "info",
  "msg": "Using existing docker-machine",
  "name": "runner-0277ea0f-srm-1598466446-3a993b31",
  "now": "2020-08-26T18:28:10.447271041Z",
  "project": 20386608,
  "runner": "0277ea0f",
  "time": "2020-08-26T18:28:10Z",
  "usedcount": 1
}
```
