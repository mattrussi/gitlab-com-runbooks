## Symptoms

* An alert in `#alerts-general` for a Sidekiq's queue not meeting its latency SLO (See Reference#1 below for visualization)

## Troubleshooting

* Click on the hyperlink that has the alert title and it should take you to the corresponding Grafana graph.
* Note down the SLO threshold and the impacted queue.
* Browse to [Kibana](https://log.gprd.gitlab.net/app/kibana#/discover?_g=()) and make sure the `pubsub-sidekiq-inf-gprd-*` index is selected. 
* Let's use the SLO threshold and impacted queue name to add filters so we can search for the logs. Example:
   * Filter 1 | Field: `json.duration`, Operator: `is between`, From: `3`, To: (leave it blank)
   * Filter 2 | Field: `json.queue.keyword`, Operator: `is`, Value: `chat_notification`
* Make sure the `Time Range` is set to big enough time to show the impact.
* See if there are `json.correlation_id`s repeating over and over again. 
* IF there is a build that is just triggering over and over again without ever stopping (See Reference#2 below for visualization) that is not good and we should stop it. 
* In order to stop the job, we will need the build IDs. They are stored in the `json.args` in the search query.

## Removing Sidekiq jobs

* See if you can use the official troubleshooting step documented in [Remove Sidekiq jobs for given parameters -- destructive](https://docs.gitlab.com/ee/administration/troubleshooting/sidekiq.html#remove-sidekiq-jobs-for-given-parameters-destructive). An example execution is shown below. The `id_list` is populated based on the `json.args` build IDs from the logs. It is a good idea to try it with a single ID first to make sure it works before tackling more. (This is to be done from Rails console)

   ```
    id_list = [380734522]

    queue = Sidekiq::Queue.new('chat_notification')
    
    while true
    queue.each do |job|
        if id_list.include?(job.args[0])
            job.delete
            puts "deleting #{job.args[0]}"
        end
    end
    end

   ```

* If the above does NOT help, then we can look at setting the stuck-in-loop builds status to `failed` and then back to `success`. See below. (This is to be done from Rails console)

   ```
   [ gprd ] production> build = Ci::Build.find(380139413)
   [ gprd ] production> build.update(status: 'failed')
    => true

   [ gprd ] production> build.update(status: 'success')
    => true
   ```

## References 

### Reference#1

![Example Sidekiq alert on a queue not meeting its latency SLO](img/sidekiq-apdex-slo-Reference1.png "Example Sidekiq alert on a queue not meeting its latency SLO")

### Reference#2

![Example Kibana log search for queue exceeding latency SLO](img/sidekiq-apdex-slo-Reference2.png "Example Kibana log search for queue exceeding latency SLO")

### Reference#3
Example issue for reference: https://gitlab.com/gitlab-com/gl-infra/production/issues/1518