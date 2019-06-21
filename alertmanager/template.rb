#!/usr/bin/env ruby

# TODO: validate ruby is available on the CI image

require 'erb'

# TODO: add these variables inside of the ops instance
slack_hook = ENV['AM_SLACK_HOOK_URL']
snitch_hook = ENV['AM_SNITCH_HOOK_URL']
prod_pagerduty = ENV['AM_PAGERDUTY_PROD']
non_prod_pagerduty = ENV['AM_PAGERDUTY_NON_PROD']

alertmanager_template = File.readlines('alertmanager.yml.erb').each(&:chomp).join

renderer = ERB.new(alertmanager_template)
File.write('chef_alertmanager.yml', renderer.result)

k8s_alertmanager_template = File
  .readlines('alertmanager.yml.erb')
  .each(&:chomp)
  .join('    ')

def k8s_template
  %{---

alertmanager:
  config:
    <%= k8s_alertmanager_template %>.
  }
end

render_k8s = ERB.new(k8s_template)
File.write('k8s_alertmanager.yml', render_k8s.result)
