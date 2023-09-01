# Gitaly multi-project migration

- Epic: <https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/935>
- Design Document: <https://gitlab.com/gitlab-com/gl-infra/readiness/-/blob/master/library/gitaly-multi-project/README.md>

## `gitalyctl`

### `500 Internal Server Error`

Symptoms:

![image of logs showing `500` error in the logs](./img/gitalyctl-500-internal-server-error.png)

[source](https://dashboards.gitlab.net/explore?orgId=1&left=%7B%22datasource%22:%22R8ugoM-Vk%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22expr%22:%22%7Bnamespace%3D%5C%22gitalyctl%5C%22%7D%20%7C%3D%20%60Internal%20Server%20Error%60%20%7C%20json%20level%3D%5C%22level%5C%22%20%7C%20level%20%3D%20%60error%60%22,%22queryType%22:%22range%22,%22datasource%22:%7B%22type%22:%22loki%22,%22uid%22:%22R8ugoM-Vk%22%7D,%22editorMode%22:%22builder%22%7D%5D,%22range%22:%7B%22from%22:%22now-6h%22,%22to%22:%22now%22%7D%7D)

Runbook:

1. Find 500 error logs in the API: <https://nonprod-log.gitlab.net/app/r/s/s2ES1>
1. Check the `json.exception.message` and `json.exception.class` for the error message. Also, notice the `json.params.value` to know which page is failing.
    ![api logs showing the error](./img/gitalyctl-500-internal-server-error-api-logs.png)
1. Verify that you also see the 500 error locally

    ```shell
    $ curl -s --header "PRIVATE-TOKEN: $(op read op://private/GitLab-Staging/PAT)" "https://staging.gitlab.com/api/v4/projects?repository_storage=nfs-file02&order_by=id&sort=asc&statistics=true&per_page=100&page=12"
    {"message":"500 Internal Server Error"}⏎
    ```

1. Find the faulty project through the rails console.

    The `offset` will depend on which page is failing, for example, `page=12` is failing so calculating the offset `(page - 1) * 100 = 1100`.

    ```shell
    Project.where("repository_storage = ?", "nfs-file02").order(id: :asc).offset(1100).limit(100).each {|p| puts "#{p.id} => #{p.valid?}"}
    ...
    219566 => false
    ```
