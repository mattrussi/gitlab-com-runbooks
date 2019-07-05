#!/usr/bin/env ruby

require 'erb'
require 'yaml'

def k8s_template
  %(---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: <%= @rule_name %>
spec:
  <%= @template %>
)
end

def render_for_k8s(file)
  @template = File
              .readlines(file)
              .each(&:chomp)
              .join('  ')

  render_k8s = ERB.new(k8s_template)
  File.write("_#{file}", render_k8s.result)
end

files = Dir.glob('*.yml')

files.each do |file|
  puts "Rendering #{file}"
  @rule_name = file.match('[\w\-_]+')[0].tr('_', '-')
  render_for_k8s(file)
  puts "Validating _#{file}"
  YAML.safe_load("_#{file}")
end
