#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

if ARGV.empty?
  puts "Usage: ruby generate-prometheus-crd.rb <directory_path>"
  exit(1)
end

shards = 6
shard_counter = 0

parent_directory = File.expand_path('..', __dir__)
rules_dir = File.join(parent_directory, ARGV[0])
rule_files = Dir.glob(File.join(rules_dir, '**', '*.{yaml,yml}'))

# This is templated without namespace
# so kubectl can target the namespace for both
# staging and production via CI
prometheus_rule_yaml = <<-YAML
---
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: ""
  labels:
    ruler: thanos
  annotations: {}
spec: {}
YAML

rule_files.each do |rule_file|
  # Load yaml file
  source_yaml = YAML.load_file(rule_file)
  source_dir = File.dirname(rule_file)

  # Don't merge yaml if its already in CRD format
  next if source_yaml.key?('kind') && source_yaml['kind'] == 'PrometheusRule'

  # Get source filename without extension
  filename_base = File.basename(rule_file)
  filename = filename_base.sub(/\.ya?ml$/, '')

  # Create new yaml
  rule_yaml = YAML.safe_load(prometheus_rule_yaml)
  rule_yaml['spec'].merge!(source_yaml)
  rule_yaml['metadata']['name'] = filename.gsub('_', '-')
  rule_yaml['metadata']['labels']['shard'] = shard_counter.to_s

  shard_counter = (shard_counter + 1) % (shards + 1)

  # Write the merged YAML content to an output file
  output_file_path = File.join(source_dir, filename_base)
  File.open(output_file_path, 'w') { |file| file.write(rule_yaml.to_yaml) }
end
