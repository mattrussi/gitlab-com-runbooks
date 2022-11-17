# Handling deployment-related incidents

If you suspect that an incident has been caused by a software change being deployed the following recovery options are available:

1. Check if the software change has a feature flag. Ideally there will be a way to disable the change to resolve the incident.
1. Rollback to a previous version to mitigate the incident. Rollbacks are only available if post-deploy migrations have not run. A rollback can only be performed by a Release Manager.
1. Apply a hot patch to mitigate the incident.
1. Deploy a new package containing a revert or fix for the problem.
