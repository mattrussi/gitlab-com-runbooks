
# Uploads #

## Intro ##

search keywords: attachments, files

uploads in production are stored in a GCS bucket: https://docs.gitlab.com/ee/administration/uploads.html#object-storage-settings

example of an upload URL: `https://gitlab.com/4dface/4dface-sdk/uploads/<secret>/image.png`

uploads in rails: `./gitlab-ce/app/models/upload.rb`

## managing uploads (deleting, renaming, etc) ##

at the moment of writing there is no UI for managing uploads: https://gitlab.com/gitlab-org/gitlab-ce/issues/23553

using the console, you can find the upload object in the rails application:
```ruby
u = Upload.find_by_secret("<secret>")
```

its path in GCS (the storage path consists of two hashes: storage hash and upload's secret):
```ruby
u.path
```

and delete the upload together with the file on GCS:
```ruby
u.destroy
```

or rename it:
```ruby
> u.secret = "<new GUID>"
> u.path
> u.path = "<path with changed secret>"
> u.save!
# move file in object storage manually to new path
```

## example ##

URL of an upload that needs to be removed: https://gitlab.com/4dface/4dface-sdk/uploads/f7a123bb72bfa73a2d0cf9c12cab99e1/image.png

get the upload's path on GCS:
```ruby
> u = Upload.find_by_secret("f7a123bb72bfa73a2d0cf9c12cab99e1")
> u.path
```

check in GCS that the file is present

remove the file from the rails app and GCS:
```ruby
Upload.find_by_secret("f7a123bb72bfa73a2d0cf9c12cab99e1").destroy
```

check again on GCS that the file is gone


## example issues ##

- rename files in an issue: https://gitlab.com/gitlab-com/gl-infra/production/issues/887
- delete an uploaded file: https://gitlab.com/gitlab-com/support/dotcom/dotcom-escalations/issues/116
