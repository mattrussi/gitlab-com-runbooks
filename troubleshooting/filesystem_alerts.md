# Errors are reported in LOG files

## First and foremost

*Don't Panic*

## Symptoms

You're likely here because you saw a message saying "Really low disk space left on <path> on <host>: <very low number>%".

Not a big deal (well, usually): a volume just got full and we need to figure out how to make some space. There are many instances where the solution is well known and it only takes a single command to fix. Keep reading.

## Resolution

First, check out if the host you're working on is one of the following:

### performance.gitlab.net

This alerts triggered on `/var/lib/influxdb/data` and `influxdb` is likely to be the culprit. Apparently there is a file handler leak somewhere and this happens regularly.

You easily can check by looking at `sudo lsof | grep deleted`: if you see a many deleted file handlers owned by influxdb then the following will do the trick:
```
sudo service influxdb restart
```

### worker*.gitlab.com

It's probably nginx. Restarting it will free up some space:
```
sudo gitlab-ctl restart nginx
```

### Anything else

Check out if kernel sources have been installed and remove them:
```
sudo apt-get purge linux-headers-*
```

You can also run an autoremove:
```
sudo apt-get autoremove
```

Next thing to remove to free up space is old log files. Run the following to delete all logs older than 2 days:

```
sudo find /var/log/gitlab -mtime +2 -exec rm {} \;
```

If that didn't work you can also remove temporary files:

```
$ sudo find /tmp -type f -mtime +2 -delete
```

If you're still short of free space you can try to delete everything older than 10 minutes.

```
sudo find /var/log/gitlab -mmin +10 -exec rm {} \;
```

Finally you can try to remove cached temp files by restarting services.
