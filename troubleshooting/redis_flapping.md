# Redis flapping

## Possible causes

 - A redis failover causes the slaves to sync from the master, that might be constrained by the client-output-buffer-limit.

## Possible fixes

Temporarily increase the `client-output-buffer-limit` on the new master

```
REDIS_MASTER_AUTH=$(sudo grep ^masterauth /var/opt/gitlab/redis/redis.conf|cut -d\" -f2)
/opt/gitlab/embedded/bin/redis-cli -a $REDIS_MASTER_AUTH config set client-output-buffer-limit "slave 0 0 0"
```
