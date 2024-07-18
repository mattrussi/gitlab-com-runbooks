# Teleport Disaster Recovery

**Table of Contents**

[TOC]

## Backup and Restore

The backup practice is based on the official Teleport
[guide](https://goteleport.com/docs/management/operations/backup-restore/#our-recommended-backup-practice).
For more details on how we made decisions and implemented back and restore process, please see this
[epic](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1357).

- Teleport Agents and [Proxy](https://goteleport.com/docs/architecture/proxy/) Service are stateless.
- We use the *Google Cloud Key Management Service* (KMS) to store and handle Teleport certificate authorities.
- We use [Firestore](https://cloud.google.com/firestore) as the [storage backend](https://goteleport.com/docs/reference/backends/)
    for Teleport and it is shared among all *Auth Service* instances.
- We also store the [session recordings](https://goteleport.com/docs/architecture/session-recording/)
    on an [Object Storage](https://cloud.google.com/storage) bucket.
- The configurations, including the `teleport.yaml` files, are version controlled in our repositories and deloyed through CI.

As a result, we only need to backup the Firestore database used by Teleport both for persisting the state of Cluster and the audit logs.

### KMS

We do not manage any certificate authority and private keys inside the cluster. They are all stored in and managed by KMS.

> To help guard against data corruption and to verify that data can be decrypted successfully,
> Cloud KMS periodically scans and backs up all key material and metadata.
> At regular intervals, the independent backup system backs up the entire datastore to both online and archival storage.
> This backup allows Cloud KMS to achieve its durability goals.

Please refer to this [deep dive document](https://cloud.google.com/docs/security/key-management-deep-dive#datastore-protection)
on Google Cloud KMS and automatic backups.

### Firestore

The `(default)` Firestore database used by the Teleport cluster is backed up
[daily](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/7cfb8a1cd38bc16c01c0fb0f436e9297357c2867/modules/teleport-project/firestore.tf#L29). These daily backups have a retention period of 30 days for Teleport staging cluster and 90 days for Teleport production cluster.

To list the current backup schedules, run the following command:

```bash
$ gcloud firestore backups schedules list --project="gitlab-teleport-staging" --database="(default)"
$ gcloud firestore backups schedules list --project="gitlab-teleport-production" --database="(default)"
```

To list the current backups, run the following command:

```bash
$ gcloud firestore backups list --project="gitlab-teleport-staging"
$ gcloud firestore backups list --project="gitlab-teleport-production"
```

### Object Storage

The `gl-teleport-staging-teleport-sessions` and `gl-teleport-production-teleport-sessions` buckets
are used for storing the [session recordings](https://goteleport.com/docs/architecture/session-recording/).

These buckets use the [Multi-Regional](https://cloud.google.com/storage/docs/locations#location-mr) location
and have [soft deletion](https://cloud.google.com/storage/docs/soft-delete)
and [versioning](https://cloud.google.com/storage/docs/object-versioning) enabled.

Objects that have been in the bucket for 30 days will be automatically transitioned to the
[Nearline](https://cloud.google.com/storage/docs/storage-classes#nearline) storage class
(see [this](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/5264ff990704be24398216378c17aff1312de735/modules/teleport-project/storage.tf#L14)).
Noncurrent objects (previous versions of objects) that have been noncurrent for 30 days will be automatically deleted
(see [this](https://ops.gitlab.net/gitlab-com/gl-infra/config-mgmt/-/blob/5264ff990704be24398216378c17aff1312de735/modules/teleport-project/storage.tf#L24)).

The combination of multi-region storage, versioning, and soft deletion provide high **redundancy** and protect against loss of objects (files).

#### Restore a Backup

To restore a backup, run the following command:

```bash
$ gcloud firestore backups schedules restore \
    --project="gitlab-teleport-staging" \
    --destination-database="(default)" \
    --source-backup="projects/PROJECT_ID/locations/LOCATION/backups/BACKUP_ID" \

$ gcloud firestore backups schedules restore \
    --project="gitlab-teleport-production" \
    --destination-database="(default)" \
    --source-backup="projects/PROJECT_ID/locations/LOCATION/backups/BACKUP_ID" \
```

For more details on how to backup and restore Firestore database,
please see the official [documentation](https://firebase.google.com/docs/firestore/backups).
