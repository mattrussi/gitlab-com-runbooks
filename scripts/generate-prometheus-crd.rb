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
mapping_file = File.join(rules_dir, ".thanos-shard-mapping")

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

  # Don't merge yaml if its already in CRD format
  next if source_yaml.key?('kind') && source_yaml['kind'] == 'PrometheusRule'

  # Load mapping file if exists

  mapping_yaml = YAML.load_file(mapping_file) if File.exist? mapping_file

  # Get source filename without extension
  filename_base = File.basename(rule_file, File.extname(rule_file))

  if mapping_yaml[filename_base]
    shard_value = mapping_yaml[filename_base]
  else
    hash_value = OpenSSL::Digest::SHA256.hexdigest(filename_base)
    shard_value = hash_value.to_i(16) % (shards + 1)
  end

  # Create new yaml
  rule_yaml = YAML.safe_load(prometheus_rule_yaml)
  rule_yaml['spec'].merge!(source_yaml)
  rule_yaml['metadata']['name'] = filename_base.gsub('_', '-')
  rule_yaml['metadata']['labels']['shard'] = shard_value.to_s

  # Write the merged YAML content to an output file
  File.open(rule_file, 'w') { |file| file.write(rule_yaml.to_yaml) }
end
