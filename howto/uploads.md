
# Uploads #

## Intro ##

search keywords: attachments, files

uploads in production are stored in a GCS bucket: https://docs.gitlab.com/ee/administration/uploads.html#object-storage-settings

example of an upload URL: https://gitlab.com/4dface/4dface-sdk/uploads/<secret>/image.png

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
Upload.find_by_secret("secret").destroy
```

## examples ##

rename files in an issue: https://gitlab.com/gitlab-com/gl-infra/production/issues/887
delete an uploaded file: https://gitlab.com/gitlab-com/support/dotcom/dotcom-escalations/issues/116
