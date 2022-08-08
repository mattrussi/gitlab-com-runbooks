# PostgreSQL PendingWALFilesTooHigh

## Symptoms

An increase on CPU Scheduling wait time, as well as accumlating WAL files on the local disk.

## Possible checks

1. Login to the sentry.gitlab.net, and check that the `wal-e` process is running:

    ```
    ps faux | grep wal-e
    ```

    A normal output looks as follows:

    ```
    postgres 61536  0.0  0.0   4504   844 ?        S    Jun15   0:00  |   \_ sh -c /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-push pg_xlog/0000000100009871000000B9
    postgres 61537  0.2  0.0 103044 28080 ?        S    Jun15   2:14  |       \_ /opt/wal-e/bin/python /opt/wal-e/bin/wal-e wal-push pg_xlog/0000000100009871000000B9

    ```

1. If the processes is not running, attempt to restart the PostgreSQL service:

    ```
    sudo -u postgres /usr/lib/postgresql/9.5/bin/pg_ctl -D /var/lib/postgresql/9.5/main restart
    ```

1. If the process is running, but seems to be stuck, check the logs:

    ```
    sudo tail -F /var/log/postgresql/postgresql-9.5-main.log
    ```

1. If you see the following in the logs, then it's time to renew these encryption keys:

    ```
    STRUCTURED: time=2022-06-16T11:46:38.106233-00 pid=57165 action=push-wal key=s3://XXX/sentry/wal_005/000000010000988100000014.lzo prefix=sentry/ seg=000000010000988100000014 state=begin
    gpg: XXB983XX: skipped: unusable public key
    gpg: [stdin]: encryption failed: unusable public key
    gpg: XXB983XX: skipped: unusable public key
    gpg: [stdin]: encryption failed: unusable public key
    ```

    ```
    cat /etc/wal-e.d/env/GPG_BIN
    cat /etc/wal-e.d/env/WALE_GPG_KEY_ID
    sudo -u postgres -H /usr/bin/gpg2 --list-keys
    ```

    To renew the key:

    ```
    sudo -u postgres -H /usr/bin/gpg2 --edit-key XXB982XX
    ### Renew the primary key
    gpg> expire
    Key is valid for? (0) 5y
    gpg> save
    ### Renew the sub key
    gpg> key 1
    gpg> expire
    gpg> save
    ```
