Some terminology:
- In Logical, we talk about _publisher_ and _subscribers_ rather than _master / leader_ and  _replicas_.

PostgreSQL version requirements:

PostgreSQL can use native logical replication as long as the version is >=10. You can replicate from 10 to 11 (or 12), and viceversa.

Configuration requirements for logical:
On the _publisher_:
- [wal_level](https://postgresqlco.nf/en/doc/param/wal_level/11/) = 'logical' (*)
- [max_replication_slots](https://postgresqlco.nf/en/doc/param/max_replication_slots/11/) > 0 (*)
- [max_wal_senders](https://postgresqlco.nf/en/doc/param/max_wal_senders/11/) >= `max_replication_slots` + #of physical replication already connected to the master.
- propper access (through `pg_hba.conf`) file must be provided (for the hypotethical user `gitlab-logical-replicator` with REPLICATION or SUPERUSER attribute:

```
host all gitlab-logical-replicator subscriber_ip_address/32 md5
```

(*) conditions already met for the current postgres instanes in GL.

On the _subscriber_ side:
- [max_replication_slots](https://postgresqlco.nf/en/doc/param/max_replication_slots/11/) > 0 
- [max_logical_replication_workers](https://postgresqlco.nf/en/doc/param/max_logical_replication_workers/11/) > 0
- [max_worker_processes](https://postgresqlco.nf/en/doc/param/max_worker_processes/11/) may need to be raised (at least to max_logical_replication_workers + 1)

DDL requirements:
- Each table *must* have a unique identifier (called a Replica Identity in this context), like:
  - Primary Key (the default)
  - Unique Index (not partial, not deferrable,with no NULLs)
- The table structure must exist in the subscriber/s previously. Can be imported with _pg_dump_ (check the `-s` option for exporting only DDL without data)

See https://www.postgresql.org/docs/11/sql-altertable.html#SQL-CREATETABLE-REPLICA-IDENTITY for more information about Replica Identity.

## How to implement logical replication for a single table (minimalist example)

1. On the _Publisher_:

1.1 CREATE a specific role for logical (if needed)
```SQL
CREATE USER "gitlab-logical-replicator" with REPLICATION encrypted password 's0meverylongpa$$'
```
1.2 Ensure access (from _subscriber_ node) through pg_hba.file:
```
host     all     gitlab-logical-replicator     subscriber.ip.address/32     md5
```

1.3 CREATE a sample origin table (you can use an existing one, as long as it have a primary key)
```sql
create table dummy (id serial primary key, data text);
```
1.4 And load the table with some data:
```
insert into dummy (data) select md5(i::text) from generate_series(1,100) i;
```
1.5 Then give the role with the right permisions:
```sql
grant SELECT on dummy to "gitlab-logical-replicator" ;
```
1.6 Finally, create the `publication` for this table:
```sql
create publication mypub for table dummy ;
```


2. On the _Subscriber_:

2.1 CREATE the sample table;
```sql
create table dummy (id serial primary key, data text);
```



2.3 CREATE the subscription:
```sql
create subscription mysub connection 'dbname=publisher host=publisher.ip.address user=gitlab-logical-replicator password=s0meverylongpa$$' publication mypub;

```

That will start the replication process. After a few seconds, you should see all the information:
```
subscriber=# table dummy limit 5;
 id |               data               
----+----------------------------------
  1 | c4ca4238a0b923820dcc509a6f75849b
  2 | c81e728d9d4c2f636f067f89cc14862c
  3 | eccbc87e4b5ce2fe28308fd9f2a7baf3
  4 | a87ff679a2f3e71d9181a67b7542122c
  5 | e4da3b7fbbce2345d7772b0674a318d5
(5 rows)
```

### Checking 
- Replication slots
You should see a replication slot in the publisher:
```
gl_infra_9545=# select * from pg_replication_slots ;
-[ RECORD 1 ]-------+------------
slot_name           | mysub
plugin              | pgoutput
slot_type           | logical
datoid              | 241470
database            | publisher
temporary           | f
active              | t
active_pid          | 31673
xmin                | 
catalog_xmin        | 2480764
restart_lsn         | 10/699B2A40
confirmed_flush_lsn | 10/699B2A78

```

### Monitoring

- "Regular" replication monitoring.

As Logical replication uses similar architecture of Streaming Repliation, it can be monitored using the [pg_stat_replication](https://www.postgresql.org/docs/11/monitoring-stats.html#PG-STAT-REPLICATION-VIEW):

```
publisher=# table pg_stat_replication ;
-[ RECORD 1 ]----+------------------------------
pid              | 31673
usesysid         | 241485
usename          | gitlab-logical-replicator
application_name | mysub
client_addr      | x.x.x.x
client_hostname  | 
client_port      | 32976
backend_start    | 2020-06-08 16:52:05.918132-03
backend_xmin     | 
state            | streaming
sent_lsn         | 10/699C2CB0
write_lsn        | 10/699C2CB0
flush_lsn        | 10/699C2CB0
replay_lsn       | 10/699C2CB0
write_lag        | 
flush_lag        | 
replay_lag       | 
sync_priority    | 0
sync_state       | async



```
- Subscription list

The [pg_stat_subscription view](https://www.postgresql.org/docs/11/monitoring-stats.html#PG-STAT-SUBSCRIPTION) provides information (on each _subscriber_ node) about each subscription plus some more detail about it (for example, it will show the extra workers involved in the initial data load):

```
subscriber=# select *, clock_timestamp() from pg_stat_subscription;
-[ RECORD 1 ]---------+------------------------------
subid                 | 16459
subname               | mysub
pid                   | 31672
relid                 | 
received_lsn          | 10/699C2D90
last_msg_send_time    | 2020-06-09 15:16:12.182561-03
last_msg_receipt_time | 2020-06-09 15:16:12.182787-03
latest_end_lsn        | 10/699C2D90
latest_end_time       | 2020-06-09 15:16:12.182561-03
clock_timestamp       | 2020-06-09 15:16:41.72603-03


```
### About sequences
One of the current limitations of logical repliation is that sequences (like the one implementing the `serial` for the _id_ column) are not replicated. 

In case of needed, you can "update" the sequence in the _subscription_ node by following this steps:

1. Get the current value of the sequence (in _publisher_):
```
publisher=# \d dummy
                            Table "public.dummy"
 Column |  Type   | Collation | Nullable |              Default              
--------+---------+-----------+----------+-----------------------------------
 id     | integer |           | not null | nextval('dummy_id_seq'::regclass)
 data   | text    |           |          | 
Indexes:
    "dummy_pkey" PRIMARY KEY, btree (id)
Publications:
    "mypub"

publisher=# select * from dummy_id_seq ;
 last_value | log_cnt | is_called 
------------+---------+-----------
        200 |      32 | t

```

2. Set the *last_value* value into _publisher_:
```
subscriber=# select setval('dummy_id_seq', 200);
 setval 
--------
    200
(1 row)
```