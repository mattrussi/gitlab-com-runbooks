# What is Programmable Search Engine?

Programmable Search Engine lets you include a search engine on your website to help your visitors find the information they're looking for. To learn more about Programmable Search Engine you can view Google documentation on Getting started with Programmable Search Engine [here](https://support.google.com/programmable-search/answer/4513751?hl=en&ref_topic=4513742)

## Configuration

To enable this service:

- A search appliance has to be created on Google's programmable search engine control [panel](https://programmablesearchengine.google.com/controlpanel/all). For `docs.gitlab.com` we have a search appliance called `GitLab Docs`.
- For billing purposes the search appliance is linked to the production billing account. This is achieved by supplying the production API [key](https://console.cloud.google.com/apis/credentials/key/1e808bc9-9f2e-41f2-a3f9-ae3db62877e1?authuser=0&project=gitlab-production).
- This search appliance uses the project `programmableSearchEngine` on google consul for the JSON API.
- The API key is saved in the production vault in 1password.
<!-- Originating issue https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/17487-->
