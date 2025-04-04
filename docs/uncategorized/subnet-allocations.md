## Summary

This document tracks the subnet allocation across multiple infrastructure
projects related to GitLab.com. Any project that requires centralized monitoring
or maintenance from ops runners should be configured to not overlap with the
gitlab-ops project for network peering.

* This doc replaces the previous [tracking spreadsheet on google docs](https://docs.google.com/spreadsheets/d/1l-Oxx8dqHqGnrQ23iVP9XGYariFGPFDuZkqFj4KOe5A/edit#gid=0)
* All environments listed on the [handbook environments page](https://about.gitlab.com/handbook/engineering/infrastructure/environments/) are covered here

## Reserving a new subnet

- Update this MR with a new allocation, pick a row that has `AVAILABLE GCP`, if
  needed we can start using previously allocated subnets for Azure
- Larger subnets can be split into smaller ones, if necessary

## Subnet Allocations

| First IP | Last IP | Subnet | Project | Description
| -------  | ------  | -----  | ------  | --------
| `10.0.0.0`      | `10.31.255.255`    | `10.0.0.0/11`    | N/A                            | RESERVED
| `10.32.0.0`     | `10.32.255.255`    | `10.32.0.0/16`   | SnowPlow                       | AWS-SnowPlow
| `10.33.0.0`     | `10.33.255.255`    | `10.33.0.0/16`   | N/A                            | Legacy Azure
| `10.34.0.0`     | `10.34.255.255`    | `10.34.0.0/16`   | gitlab-vault                   | Vault and Vault-nonprod GKE
| `10.35.0.0`     | `10.35.255.255`    | `10.35.0.0/16`   | N/A                            | Legacy Azure
| `10.36.0.0`     | `10.39.255.255`    | `10.36.0.0/14`   | N/A                            | Legacy Azure
| `10.40.0.0`     | `10.43.255.255`    | `10.40.0.0/14`   | N/A                            | Legacy Azure
| `10.44.0.0`     | `10.47.255.255`    | `10.44.0.0/14`   | N/A                            | Legacy Azure
| `10.48.0.0`     | `10.63.255.255`    | `10.48.0.0/12`   | N/A                            | Legacy Azure
| `10.64.0.0`     | `10.95.255.255`    | `10.64.0.0/11`   | gitlab-production              | GKE pods
| `10.96.0.0`     | `10.127.255.255`   | `10.96.0.0/11`   | gitlab-staging                 | GKE pods
| `10.128.0.0`    | `10.159.255.255`   | `10.128.0.0/11`  | gitlab-pre                     | GKE pods
| `10.160.0.0`    | `10.163.255.255`   | `10.160.0.0/14`  | gitlab-analysis                | GKE pods
| `10.164.0.0`    | `10.167.255.255`   | `10.164.0.0/14`  | gitlab-analysis                | GKE pods
| `10.168.0.0`    | `10.175.255.255`   | `10.168.0.0/13`  | gitlab-ops                     | GKE pods
| `10.176.0.0`    | `10.183.255.255`   | `10.176.0.0/16`  | gitlab-staging-db              | **Repeatable db provisioning**
| `10.176.0.0`    | `10.183.255.255`   | `10.177.0.0/16`  | gitlab-production-db           | **Repeatable db provisioning**
| `10.176.0.0`    | `10.183.255.255`   | `10.178.0.0/16`  | gitlab-sandbox-db              | **Repeatable db provisioning**
| `10.176.0.0`    | `10.183.255.255`   | `10.179.0.0/16`  | N/A                            | AVAILABLE GCP
| `10.176.0.0`    | `10.183.255.255`   | `10.180.0.0/16`  | N/A                            | AVAILABLE GCP
| `10.176.0.0`    | `10.183.255.255`   | `10.181.0.0/16`  | N/A                            | AVAILABLE GCP
| `10.176.0.0`    | `10.183.255.255`   | `10.182.0.0/16`  | N/A                            | AVAILABLE GCP
| `10.176.0.0`    | `10.183.255.255`   | `10.183.0.0/16`  | N/A                            | AVAILABLE GCP
| `10.184.0.0`    | `10.191.255.255`   | `10.184.0.0/13`  | N/A                            | AVAILABLE GCP
| `10.185.2.0`    | `10.185.2.255`     | `10.185.2.0/24`  | gitlab-subscriptions-staging   | Stgsub GCP
| `10.185.3.0`    | `10.185.3.255`     | `10.185.3.0/24`  | gitlab-subscriptions-staging   | Stgsub GCP 
| `10.185.4.0`    | `10.185.4.255`     | `10.185.4.0/24`  | gitlab-subscriptions-staging   | Stgsub GKE
| `10.185.5.0`    | `10.185.5.255`     | `10.185.5.0/24`  | gitlab-subscriptions-staging   | Stgsub GKE Service 
| `10.185.6.0`    | `10.185.6.255`     | `10.185.6.0/24`  | gitlab-subscriptions-prod      | Prdsub GCP
| `10.185.7.0`    | `10.185.7.255`     | `10.185.7.0/24`  | gitlab-subscriptions-prod      | Prdsub GCP 
| `10.185.8.0`    | `10.185.8.255`     | `10.185.8.0/24`  | gitlab-subscriptions-prod      | Prdsub GKE
| `10.185.9.0`    | `10.185.9.255`     | `10.185.9.0/24`  | gitlab-subscriptions-prod      | Prdsub GKE Service
| `10.186.0.0`    | `10.186.255.255`   | `10.186.0.0/16`  | gitlab-subscriptions-staging   | Stgsub GKE Pods
| `10.187.0.0`    | `10.187.255.255`   | `10.187.0.0/16`  | gitlab-subscriptions-prod      | Prdsub GKE Pods
| `10.192.0.0`    | `10.199.255.255`   | `10.192.0.0/13`  | N/A                            | Legacy Azure
| `10.200.0.0`    | `10.207.255.255`   | `10.200.0.0/13`  | N/A                            | Legacy Azure
| `10.208.0.0`    | `10.208.0.255`     | `10.208.0.0/24`  | gitlab-release                 | **Release GCP**
| `10.209.0.0`    | `10.209.0.255`     | `10.209.0.0/24`  | gitlab-dev                     | **Dev GCP**
| `10.216.0.0`    | `10.223.255.255`   | `10.216.0.0/13`  | gitlab-production              | **Production GCP**
| `10.251.0.0`    | `10.251.255.255`   | `10.251.0.0/16`  | gitlab-dr                      | **DR GCP**
| `10.224.0.0`    | `10.231.255.255`   | `10.224.0.0/13`  | gitlab-staging                 | **Staging GCP**
| `10.232.0.0`    | `10.239.255.255`   | `10.232.0.0/13`  | gitlab-pre                     | **PreProd GCP**
| `10.240.0.0`    | `10.247.255.255`   | `10.247.0.0/13`  | gitlab-testbed                 | **Testbed GCP**
| `10.248.0.0`    | `10.248.255.255`   | `10.248.0.0/16`  | N/A                            | **PreProd GCP**
| `10.249.0.0`    | `10.249.255.255`   | `10.249.0.0/16`  | N/A                            | **PreProd GCP**
| `10.250.0.0`    | `10.250.255.255`   | `10.250.0.0/16`  | gitlab-ops                     | **Ops GCP**
| `10.252.0.0`    | `10.252.255.255`   | `10.252.0.0/16`  | gitlab-restore                 | **Restore GCP**
| `10.253.0.0`    | `10.253.255.255`   | `10.253.0.0/16`  | N/A                            | **Ops GCP US-Central1**
| `10.254.0.0`    | `10.254.255.255`   | `10.254.0.0/16`  | N/A                            | Legacy Azure
| `10.255.0.0`    | `10.255.255.255`   | `10.255.0.0/16`  | db-benchmarking                | **DB Benchmarking GCP**
