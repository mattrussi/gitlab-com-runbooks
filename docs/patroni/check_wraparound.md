# Check the status of transaction wraparound Runbook


## Intro
The autovacuum process executes a "special" maintenance task called **to prevent wraparound** or **wraparound protection** on tables that the TXID reaches the autovacuum_freeze_max_age. Sometimes this activity can be annoying in a high workload on the database server due to the expense of consuming additional resources. A manual `frozen vacuum` command helps avoid this "situation", but running `frozen vacuum` on the entire database can slow down the database server, hence the importance of monitoring and executing it by table(especially on big tables) it is a smart decision


## Verify the status wraparound on each table in GitLab

Is important be monitoring de `TXID` of the tables to check if this table is near to a wraparound, whit the following [script](scripts/wraparound.sh) you can check the tables' status and generate `FREEZE` command, please on the `leader` (primary) server:


```
#check tables with more than 95 % of TXID and more than 10GB
sh wraparound.sh -p 95 -m check -s 10000000000
```

You will get an output like similar to:
```
 mode: check, size: 10000000000, percent: 95
   full_table_name   | pg_size_pretty | freeze_age | percent 
---------------------+----------------+------------+---------
 push_event_payloads | 72 GB          |  188675977 |      98
 notes               | 431 GB         |  184676635 |      96
(2 rows)

```

The previous query filter the tables bigger than 10GB and more than 95% of freeze_age (can change if needed)

## Execute `FREEZE` maintenance task in  GitLab
To execute the `FREEZE` maintenance task you can get the commands from the following query:

```
sh wraparound.sh -p 95 -m  generate -s 10000000000
```

The previous query returns the `FREEZE` commands for maintenance (can filter by tablename)

You will get an output like similar to:
```        
mode: generate, size: 10000000000, percent: 95
                            command                             
----------------------------------------------------------------
 VACUUM FREEZE ANALYZE push_event_payloads; select pg_sleep(2);
 VACUUM FREEZE ANALYZE notes; select pg_sleep(2);
(2 rows)


```

You can execute the previous commands in the `leader`(primary) server   with discretion and on off-peak times to do not impact the primary due to the expense of consuming additional resources.

You can check the `help` for the script

```       
sh wraparound.sh -h

Script for check wraparound status and generate FREEZE command 
wraparound.sh  -m check -p 95
options
 mode: -m check/generate (default check)
 size: -s size threshold of tables to check/generate (default 10000000000 [10GB])
 percent: -p % threshold of age (default 95 )



```