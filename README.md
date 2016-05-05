# Gitlab On Call Run Books

The aim of this project is to have a quick guide of what to do when an emergency arrives

## What to do when

* [The NFS server `backend4` is gone](troubleshooting/nfs-server.md)

## How do I

* [Deny a path in the load balancers](howto/block-things-in-haproxy.md#deny-a-path-with-the-delete-http-method)
* [Isolate a worker by disabling the service in the LBs](howto/block-things-in-haproxy.md#disable-a-whole-service-in-a-load-balancer)
* [Restart unicorn with a zero downtime](howto/manage-workers.md#restart-unicorn-with-a-zero-downtime)
* [Gracefully restart sidekiq jobs](howto/manage-workers.md#gracefully-restart-sidekiq-jobs)
* [Reload CheckMK metrics](howto/manage-checkmk.md#reload_host_metrics)

## General guidelines in an emergency

* Join the `#alerts` channel
* Organize
  * open a hangout if it will save time: https://plus.google.com/hangouts/_/gitlab.com?authuser=1
  * share the link in the alerts channel
* If you need someone to do something, give a direct command: _@someone: please run `this` command_
* Be sure to be in sync - if you are going to reboot a service, say so: _I'm bouncing server X_
* Fix first, ask questions later.
* Gather information when the outage is done - logs, samples of graphs, whatever could help figuring out what happened
* Open an issue

## Adding runbooks rules

* Make it quick - add links for checks
* Don't make me think - write clear guidelines, write expectations
* Recommended structure
  * Symptoms - how can I quickly tell that this is what is going on
  * Pre-checks - how can I be 100% sure
  * Resolution - what do I have to do to fix it
  * Post-checks - how can I be 100% sure that it is solved
  * Rollback - optional, how can I undo my fix


# But always remember!

![Dont Panic](img/dont_panic_towel.jpg)
