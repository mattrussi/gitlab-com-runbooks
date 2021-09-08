# Interacting with Consul

## CLI

The `consul` CLI is very extensive.  Check out [Consul's Commands Documentation](https://www.consul.io/commands)

## Useful Commands

To [identify the current server](https://www.consul.io/commands/operator/raft) with the leader role:
```
$ consul operator raft list-peers
Node                ID                                    Address          State     Voter  RaftProtocol
consul-01-inf-gstg  2c3cf733-0f27-982e-a53c-1447409c161d  10.224.4.2:8300  follower  true   3
consul-03-inf-gstg  28580308-0012-eac2-85e8-22e2d1f25d16  10.224.4.4:8300  leader    true   3
consul-04-inf-gstg  2abc4eaa-e906-ca41-925b-2a3b85405fd5  10.224.4.5:8300  follower  true   3
consul-05-inf-gstg  7386d511-4acc-ef91-b5e3-a000fffa4eb6  10.224.4.6:8300  follower  true   3
consul-02-inf-gstg  dd04fcd5-7c30-a3b8-b351-daed6c80a692  10.224.4.3:8300  follower  true   3
```

To [follow the debug logs](https://www.consul.io/commands/monitor) of a consul agent:
```
consul monitor -log-level debug
```

### Get the full key/value tree as json

```
consul kv export | jq .
```

### Some commands interesting for patroni

* get the patroni leader
  ```
  consul kv get service/gstg-pg12-patroni-registry/leader
  ```
* get the patroni attributes of a patroni node
  ```
  consul kv get service/pg12-ha-cluster-stg/members/patroni-06-db-gstg.c.gitlab-staging-1.internal
  ```
* The dns name of the primary db: `master.patroni.service.consul`
* The round-robin dns name of the replicas: `replica.patroni.service.consul`

More to be found [here](../pgbouncer/patroni-consul-postgres-pgbouncer-interactions.md).

## External Queries

Our primary use of Consul is for service discovery.  If you know the name of the
service you intend on querying, you can perform a lookup to the agent locally:

```
dig @127.0.0.1 -p 8600 <service_name>
```

## Web UI

We enable the web UI, but do not easily expose it.  Follow the instructions
below to access the full catalog of consul using their UI:

1. `ssh -L 8500:localhost:8500 <consul_hostname>`
1. Open a browser and point it to `http://localhost:8500`
1. Enjoy
