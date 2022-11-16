# Interacting with Consul

## CLI

The `consul` CLI is very extensive.  Check out [Consul's Commands Documentation](https://www.consul.io/commands)

## Useful Commands

To [identify the current server](https://www.consul.io/commands/operator/raft) with the leader role:

```
$ consul operator raft list-peers
Node                       ID                                    Address             State     Voter  RaftProtocol
consul-gl-consul-server-3  c929bb0e-0263-c870-4b7e-1ea7a25a39a2  10.227.16.79:8300   leader    true   3
consul-gl-consul-server-2  e607642d-a79c-838a-31bd-da25a2c77bfd  10.227.11.13:8300   follower  true   3
consul-gl-consul-server-1  5d947b27-ef5f-f3c6-17b1-bd93b19e3fc0  10.227.22.175:8300  follower  true   3
consul-gl-consul-server-0  5342d066-32b5-29cb-7c10-51aa5c89e23c  10.227.2.236:8300   follower  true   3
consul-gl-consul-server-4  2e3075d9-f13f-429d-0010-d2190a40bc31  10.227.5.16:8300    follower  true   3
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

## Web UI and local Consul CMD

We enable the web UI, but do not easily expose it.  Follow the instructions
below to access the full catalog of consul using their UI:

1. Connect to the GKE cluster where Consul is hosted:

    ```
    glsh kube use gprd
    ```

2. On a separate terminal, forward the Consul Server service port:

    ```
    kubeclt port-forward service/consul-gl-consul-expose-servers 8500:8500 -n consul
    ```

3. Open a browser and point it to `http://localhost:8500`
4. You can also use the `consul` command on a terminal. Eg:

    ```
    consul members
    ```

5. Enjoy

## Consul Server Maintenance

TODO: this only applies to Consul running on VMs and we are not doing that anymore. Do we need this?

When needing to perform maintenance on consul, it would be wise to gracefully
remove the node from the cluster to prevent as much disruption as possible.
Removing a node from the cluster prevents any node from connecting to it and
brings down the service preventing failover to that node.

1. On the consul server `consul leave` - This will gracefully leave and shutdown
   the consul service
1. Prior to starting consul, one may need to remove any snapshots located inside
   of the data directory
1. Start consul - `systemctl start consul`
1. Validate that it is has joined the cluster as a follower
