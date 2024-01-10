## release bastion hosts

### How to start using them

Add the following to your `~/.ssh/config` (specify your username and path to ssh private key):

```
# GCP staging bastion host
Host lb-bastion.release.gitlab.com
        User                            YOUR_SSH_USERNAME

# release boxes
Host *.gitlab-release.internal
        PreferredAuthentications        publickey
        ProxyCommand                    ssh lb-bastion.release.gitlab.com -W %h:%p
```
