# Life of a Git Request

Work in progress:
* Issue: https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/10389
* [Style guide](/handbook/engineering/infrastructure/tutorials/tips_for_tutorial_writing.html)


## Learning objectives

* Learn which application and infrastructure components are involved in handling `git` requests.
* Learn how the call paths differ depending on whether the client is using SSH or HTTPS as their secure transport protocol.
* Learn how to observe git requests using Kibana to find related log events.

Readers are assumed to have a basic familiarity with Git.  You should know what a git repository is, that `git clone` makes a local copy
of that repo, and that `git fetch` refreshes that local copy by sending the server an inventory of what is already stored locally and
asking the server to send whatever new objects are missing.

This tutorial does not cover the internal details of how Gitaly and `git` perform these tasks.  Here we just outline the series of service
calls and demonstrate how to observe those service calls through the logging infrastructure specific to GitLab.com.


## Introduction

This tutorial traces a few common `git` commands (e.g. `git clone`) through the GitLab.com infrastructure, contrasting Git-over-SSH and Git-over-HTTP.
Other git operations follow the same paths and can be traced in the same way.

Depending on whether the client cloned the git repo using SSH or HTTPS, the subsequent git operations will take a different path through
the GitLab infrastructure but ultimately arrive at the same place (Gitaly) and produce the same outcome for the end-user's `git` client.

By learning how to trace a single request, view what characteristics are logged, and filter to find other similar requests, we can:
* troubleshoot unexpected behavior
* identify abnormal changes in request or response characteristics (e.g. huge increase in git-fetch rate for a specific repo from a specific client IP)
* be aware of what is and is not observable with existing metrics, logging, and instrumentation


## Call path between GitLab application components

See the GitLab product documentation, which includes a concise sequence diagram and explanation for both Git-over-HTTP and Git-over-SSH,
illustrating the differences and similarities in these two distinct call paths.

https://docs.gitlab.com/ee/development/architecture.html#gitlab-git-request-cycle

The above product documentation covers the relevant application components and their interactions -- the behaviors
that are typical of any GitLab deployment.  The following notes cover additional details specific to the GitLab.com environment:
* The "Git on client" component is the host running the end-user's `git` command, typically a host somewhere on the Internet or in GitLab.com's pool of CI/CD job runners.
* The Nginx, Workhorse, and Rails components run on hosts named `git-XX`.
* The Gitaly and "Git on server" components run on hosts named `file-XX`.
* Several infrastructure components sit between the "Git on client" and the "Nginx" components.  In order, these include:
  * Cloudflare: Provides DDoS protection, web-application firewall, and security control point.  Acts as a TLS endpoint for HTTPS but just a TCP pass-through for SSH.
  * GCP external load balancer: TCP-layer routing rule that forwards connections to a pool of HAProxy nodes.
  * HAProxy: Routes both Git-over-SSH and Git-over-HTTP requests to the `git-XX` backend pool, where the request enters Nginx and we return to the sequence diagram.
    Note also that the HAProxy nodes represent the outer edge of our GCP infrastructure.  Like Cloudflare, they act as TLS endpoints for HTTPS and TCP-passthrough for SSH.


## Demo: Observing an example `git` request

As always, tracing entails peeling back a layer of facade.
We will see a little of Git's internal behavior, but our main focus in this tutorial is to show the observability tools available to you.
You are not expected to understand the inner workings of git.  Just being able to see the discrete phases of a request can aid in troubleshooting a stall or error.

### Client-side view

Normally the daily-use high-level "porcelain" git commands like `git clone` and `git fetch` only output a summary of results, but with tracing enabled,
we can see the series of internal "plumbing" commands that run under the hood.

Note that this form of tracing is not required to see the server-side log events that we will examine next.
These client-side tracing options only affect the verbosity of the client-side output.

Git's built-in tracing is controlled via environment variables.  Especially useful examples:
* Setting `GIT_TRACE=/tmp/git-trace.log` enables general tracing messages, including local and remote execution of built-in git commands.
  * Must use an absolute path for the filename.
  * If the output file exists, new output is appended (not overwritten).
  * Alternately, setting `GIT_TRACE=1` is the same as above, except the trace output goes to standard error and is interleaved with other output.
* Setting `GIT_TRACE_CURL=/tmp/git-curl.log` and `GIT_TRACE_CURL_NO_DATA=1` enables logging HTTP request and response headers for a Git-over-HTTP command.

These and more tracing options are documented in:
* the [git manpage](https://git-scm.com/docs/git#Documentation/git.txt-codeGITTRACEcode) or `man git`
* the [Git source code documentation](https://github.com/git/git/blob/master/Documentation/git.txt)

#### 1st tracing attempt

Let's pick a small repo and clone it while enabling the general-purpose client-side tracing (`GIT_TRACE`).

```shell
# Tip: Setting the TZ environment variable to UTC makes my local shell's timestamps easier to compare to server-side logs, which also use UTC.

$ export TZ=UTC

$ GIT_TRACE=/tmp/git-trace.log git clone https://gitlab.com/gitlab-org/gitlab-docs.git /tmp/git-trace-test
Cloning into '/tmp/git-trace-test'...
remote: Enumerating objects: 2775, done.
remote: Counting objects: 100% (2775/2775), done.
remote: Compressing objects: 100% (507/507), done.
remote: Total 10274 (delta 2612), reused 2342 (delta 2265), pack-reused 7499
Receiving objects: 100% (10274/10274), 21.97 MiB | 7.86 MiB/s, done.
Resolving deltas: 100% (6485/6485), done.

$ cat /tmp/git-trace.log
23:04:51.527628 git.c:344               trace: built-in: git clone https://gitlab.com/gitlab-org/gitlab-docs.git /tmp/git-trace-test
23:04:51.559198 run-command.c:646       trace: run_command: unset GIT_DIR; ssh git@gitlab.com 'git-upload-pack '\''gitlab-org/gitlab-docs.git'\'''
23:04:54.275131 run-command.c:646       trace: run_command: git index-pack --stdin -v --fix-thin '--keep=fetch-pack 30882 on saoirse' --check-self-contained-and-connected
23:04:54.278421 git.c:344               trace: built-in: git index-pack --stdin -v --fix-thin '--keep=fetch-pack 30882 on saoirse' --check-self-contained-and-connected
23:04:57.362139 run-command.c:646       trace: run_command: git rev-list --objects --stdin --not --all --quiet '--progress=Checking connectivity'
23:04:57.365339 git.c:344               trace: built-in: git rev-list --objects --stdin --not --all --quiet '--progress=Checking connectivity'
```

In addition to the normal output of `git clone`, we can see several interesting things in the trace output.
* We see "built-in" git commands, including both the high-level "clone" and low-level "index-pack" and "rev-list".
* We also see "run_command" trace output which includes non-git commands like "ssh".

Hey, wait a second...  Here's a surprise twist!
Look at that 2nd line of trace output.  Why was `ssh` run when I specified cloning an HTTP-based URL?

```
trace: run_command: unset GIT_DIR; ssh git@gitlab.com ...
```

It turns out this silent conversion to use SSH instead of HTTPS happened because...
In my `$HOME/.gitconfig` I had configured it to do that substitution a few months ago and forgot to remove it!

```shell
$ git config --global --get-regexp 'url.*'
url.git@gitlab.com:.insteadof https://gitlab.com/
```

#### 2nd tracing attempt

Let's disable that config entry.

```shell
$ git config --global --edit
```

Now we can repeat the experiment and see what the trace looks like when it really uses git-over-http.

```shell
$ rm -rf /tmp/git-trace-test/ /tmp/git-trace.log

$ GIT_TRACE=/tmp/git-trace.log git clone https://gitlab.com/gitlab-org/gitlab-docs.git /tmp/git-trace-test
Cloning into '/tmp/git-trace-test'...
remote: Enumerating objects: 2775, done.
remote: Counting objects: 100% (2775/2775), done.
remote: Compressing objects: 100% (507/507), done.
remote: Total 10274 (delta 2612), reused 2342 (delta 2265), pack-reused 7499
Receiving objects: 100% (10274/10274), 21.97 MiB | 8.03 MiB/s, done.
Resolving deltas: 100% (6485/6485), done.

$ cat /tmp/git-trace.log
23:10:51.531056 git.c:344               trace: built-in: git clone https://gitlab.com/gitlab-org/gitlab-docs.git /tmp/git-trace-test
23:10:51.562453 run-command.c:646       trace: run_command: git-remote-https origin https://gitlab.com/gitlab-org/gitlab-docs.git
23:10:52.114174 run-command.c:646       trace: run_command: git fetch-pack --stateless-rpc --stdin --lock-pack --thin --check-self-contained-and-connected --cloning https://gitlab.com/gitlab-org/gitlab-docs.git/
23:10:52.116457 git.c:344               trace: built-in: git fetch-pack --stateless-rpc --stdin --lock-pack --thin --check-self-contained-and-connected --cloning https://gitlab.com/gitlab-org/gitlab-docs.git/
23:10:52.725389 run-command.c:646       trace: run_command: git index-pack --stdin -v --fix-thin '--keep=fetch-pack 31838 on saoirse' --check-self-contained-and-connected --pack_header=2,10274
23:10:52.730476 git.c:344               trace: built-in: git index-pack --stdin -v --fix-thin '--keep=fetch-pack 31838 on saoirse' --check-self-contained-and-connected --pack_header=2,10274
23:10:55.635017 run-command.c:646       trace: run_command: git rev-list --objects --stdin --not --all --quiet '--progress=Checking connectivity'
23:10:55.638511 git.c:344               trace: built-in: git rev-list --objects --stdin --not --all --quiet '--progress=Checking connectivity'
```

Now the trace output shows git-over-HTTP:
* Git locally runs `git-remote-https` to establish a TLS session with the remote URL.
* Git then runs the built-in commands "fetch-pack", "index-pack", and "rev-list".


#### 3rd tracing attempt

In addition to the general tracing, let's try also tracing the actual HTTP requests sent to the server by git.

To do so, we will add the following two environment variables to our command:
* `GIT_TRACE_CURL=/tmp/git-curl.log`
* `GIT_TRACE_CURL_NO_DATA=1`

```shell
$ export TZ=UTC

$ rm -rf /tmp/git-trace-test/ /tmp/git-trace.log /tmp/git-trace-curl.log

$ GIT_TRACE=/tmp/git-trace.log GIT_TRACE_CURL=/tmp/git-trace-curl.log GIT_TRACE_CURL_NO_DATA=1 git clone https://gitlab.com/gitlab-org/gitlab-docs.git /tmp/git-trace-test
Cloning into '/tmp/git-trace-test'...
remote: Enumerating objects: 2775, done.
remote: Counting objects: 100% (2775/2775), done.
remote: Compressing objects: 100% (507/507), done.
remote: Total 10274 (delta 2612), reused 2342 (delta 2265), pack-reused 7499
Receiving objects: 100% (10274/10274), 21.97 MiB | 6.92 MiB/s, done.
Resolving deltas: 100% (6485/6485), done.
```

The curl tracing output is much more verbose, even without logging the data.

```shell
$ wc -l /tmp/git-trace-curl.log
117 /tmp/git-trace-curl.log
```

But for now we just want to see what HTTP requests were sent to the server.

```shell
$ grep 'Send.*HTTP' /tmp/git-trace-curl.log
00:18:52.539909 http.c:654              => Send header: GET /gitlab-org/gitlab-docs.git/info/refs?service=git-upload-pack HTTP/1.1
00:18:53.353662 http.c:654              => Send header: POST /gitlab-org/gitlab-docs.git/git-upload-pack HTTP/1.1
```

How do these compare to what the server-side logs show?  Let's find out.


### Server-side view

**TODO:**

* Show how to find in Kibana the associated log events from Workhorse, Rails, and Gitaly.
  * Workhorse:
    * Kibana index: `pubsub-workhorse-inf-gprd-*`
    * Filters: `json.type: git` `json.remote_ip: <my public IP>`
* Walk through the server-side logs, starting with Workhorse.
  * HTTP `GET /gitlab-org/gitlab-docs.git/info/refs?service=git-upload-pack`
  * HTTP `POST /gitlab-org/gitlab-docs.git/git-upload-pack`
* Show how to filter to all requests of this type.
  * Screenshot the trend for this request type's log event rate over the last 24-hour timespan.
  * Compare the shape and magnitude to the Grafana dashboard for the Gitaly service.


## Exercises

* Under your personal namespace on GitLab.com, [create a new git repo](https://gitlab.com/projects/new) using a distinctive name that will be easy to search for in Kibana.
  Then on your laptop, `git clone` the repo and run a few git operations, such as `git pull` or `git push`.
  * What log entries can you find in Kibana associated with your new repo?
  * Can you find relationships between the log events from Rails versus Gitaly (i.e. Kibana indexes `pubsub-rails-inf-gprd-*` versus `pubsub-gitaly-inf-gprd-*`)?
* Make 2 local clones of a repo, one using git-over-http and the other using git-over-ssh.
  In Kibana, find the log events triggered by both of your `git clone` commands.  How do they differ?


## Summary

Conclude with a summary of key points that ties the presented content back to the learning objectives.
How does the presented content satisfy each of the learning objectives?
Here we can use the more concrete terms and concepts covered in the material.

The goal here is to give the reader a moment to reflect on the distance traveled and enjoy a milestone on their journey.

For the tutorial author, this is an opportunity to reflect on whether the content aligns well with the learning objectives and to refine scope if needed.


## Learn more

* GitLab's intro tutorial on using git.
  Offers a gentle introduction to getting comfortable using `git` on the command-line.
* GitLab documentation of Git-over-SSH and Git-over-HTTP.
  Cited earlier in this tutorial.  Explains the sequence of events for handling an example `git fetch` request, illustrating the service calls between GitLab components.
* GitLab product docs for GitLab-Shell and Gitaly.
  Provides more background on how `git` client requests are translated into RPC calls to Gitaly, which then runs the server-side `git` commands on its local copy of the bare git repo.
* Path to the live HAProxy config files and links to the chef recipe and roles that control it.
  To see exactly how HAProxy decides where to route which types of requests, all of its routing rules are in this one config file.
  Looking at the live file is easier than looking in Chef because chef composes the file from attributes that are spread across several places (recipe, role, secrets).
* Dashboard and Kibana links.
  To explore trends in live traffic and get a sense of what "normal" looks like for Gitaly and its callers, you can play with the service dashboards or browse log events in Kibana.
