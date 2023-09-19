#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'openssl'

if ARGV.empty?
  puts "Usage: ruby generate-prometheus-crd.rb <directory_path>"
  exit(1)
end

shards = 6

parent_directory = File.expand_path('..', __dir__)
rules_dir = File.join(parent_directory, ARGV[0])
rule_files = Dir.glob(File.join(rules_dir, '**', '*.{yaml,yml}'))

# Initialize hash in case mapping file doesn't exist
shard_mapping = {}

# Load mapping file if it exists
mapping_file = File.join(rules_dir, ".thanos-shard-mapping")
if File.exist?(mapping_file)
  shard_mapping = YAML.load_file(mapping_file)
end

# Initialize the shard counter
shard_counter = 0

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

  # Get source filename without extension
  filename_base = File.basename(rule_file, File.extname(rule_file))

  # Assign a shard value or retrieve the shard value from the mapping
  shard_value = shard_mapping.fetch(filename_base) do
    shard_value = shard_counter
    shard_mapping[filename_base] = shard_value
    shard_counter = (shard_counter + 1) % (shards + 1)
    shard_value
  end

  puts "Shard Counter: #{shard_counter}"

  rule_yaml = YAML.safe_load(prometheus_rule_yaml)

  # Don't merge yaml if its already in CRD format
  unless source_yaml.key?('kind') && source_yaml['kind'] == 'PrometheusRule'
    rule_yaml['spec'].merge!(source_yaml)
  end
  
  rule_yaml['metadata']['name'] = filename_base.gsub('_', '-')
  rule_yaml['metadata']['labels']['shard'] = shard_value.to_s

  # Write the merged YAML content to an output file
  File.open(rule_file, 'w') { |file| file.write(rule_yaml.to_yaml) }
end

# Saving mapping
File.open(mapping_file, 'w') { |file| file.write(shard_mapping.to_yaml) }