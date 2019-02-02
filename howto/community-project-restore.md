## Community Project Restoration
This document goes into the necessary details to assist in restoring an
accidental deletion.

### Components
* Database
* Project Repo Data
* Project Wiki Data
* There's more but we haven't encountered/practiced necessary mechanisms for a
  restoration.  Examples, docker registry data and artifacts

### Coordination
* This requires coordination with at least two members that have production
  access:
  * A Database Administrator - known as DBRE in the rest of this document
  * A Systems Administrator - known as SRE in the rest of this document
* A restoration process should be assigned to available team members and
  coordination between the two will govern how to progress through this process
* It is strongly suggested to read through this entire document before
  proceeding to ensure one can answer all required questions and agree upon a
  validation method

### Database (DBRE responsibilities)

### File Data (SRE responsibilities)
* We need multiple things to help perform the restoration of data for a repo:
  1. The storage server the data was previously living on
  1. The full path of where the database thought the data was at
  1. The last known good date and time stamp of when the data was available

#### Retrieving This information
##### If the Project is **NOT** in GitLab
* If a project has been removed entirely from our database, it'll be difficult
  to get the above information.
  * Coordinate with the DBRE who can provide this information upon restoration
    of the project in the database.

##### If the project is in GitLab
* These items can be found by issuing the following:
  1. `Project.find(<PROJECTID>).repository_storage`
  1. `Project.find(<PROJECTID>).disk_path`
* At this point we can log into that file server, browse to this location and
  see if the repo and wiki data might still exist.  If our cleanup process has
  cleaned them up, we'll now need to perform a restoration from backup.  See
  further details below
  * If our regular cleanup process hasn't removed the repos yet, you'll see them
    on disk as `<repository disk path>+deleted+<some time stamp>.git`
  * We can simply move them to the location specified by our database to put the
    data back in the correct location for GitLab to work properly
  * This must be done for both git repo and the wiki

#### Restoring from Disk Snapshot
* Using the timestamp provided, browse available Disk Snapshots in the Google
  Compute Console.
* Find the latest previous for the correct file server in relation to the known
  timestamp
* Use that snapshot to create a disk
* Mount that disk to an appropriate server
* Log into this server, mount the disk and browse to the location on disk where
  the git repo and wiki should live
* Create a tarball of each of these, move these tarballs to a secondary safe
  location
* Remove the file mount, unmount the disk from the server in the GCP console
* Delete the created disk
* Proceed to restore the data to the original file server in the correct
  location
* Ensure the data maintains proper ownership `git:root`

## Questions to Ask for coordination
* Will the project be restored to it's original place in GitLab?
  * Would the project ID's change?
  * Answering this question will impact the storage location on disk the repo
    will live
