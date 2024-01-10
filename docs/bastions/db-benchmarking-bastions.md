## db-benchmarking bastion hosts

### How to start using them

Add the following to your `~/.ssh/config` (specify your username and path to ssh private key):

```
# GCP db-benchmarking bastion host
Host lb-bastion.db-benchmarking.gitlab.com
        User                            YOUR_SSH_USERNAME

# db-benchmarking boxes
Host *.gitlab-db-benchmarking.internal
        PreferredAuthentications        publickey
        ProxyCommand                    ssh lb-bastion.db-benchmarking.gitlab.com -W %h:%p
```

Once your config is in place, test it by ssh'ing to the jmeter host:

```
ssh jmeter-01-inf-db-benchmarking.c.gitlab-db-benchmarking.internal
```
