#!/bin/bash

declare -a indices

export indices=(
  camoproxy
  chef
  consul
  customers-puma
  customers-rails
  customers-system
  fluentd
  gitaly
  gcs
  gcp-events
  gke
  gke-audit
  gke-systemd
  jaeger
  kas
  mailroom
  monitoring
  pages
  postgres
  praefect
  pubsubbeat
  puma
  pvs
  rails
  redis
  registry
  runner
  shell
  sidekiq
  system
  workhorse
)
