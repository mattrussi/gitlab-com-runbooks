#!/usr/bin/env ruby
# frozen_string_literal: true
require 'yaml'
require_relative '../lib/jsonnet_wrapper'

# For basic type validations, use JSON Schema in https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog.schema.json
class ValidateServiceMappings
  DEFAULT_RAW_CATALOG_PATH = File.join(__dir__, "..", "services", "raw-catalog.jsonnet")

  def initialize(raw_catalog_path = DEFAULT_RAW_CATALOG_PATH)
    @raw_catalog_path = raw_catalog_path
  end

  def validate
    service_catalog = JsonnetWrapper.new.parse(@raw_catalog_path)

    teams = service_catalog["teams"]
    services = service_catalog["services"]

    team_map = teams.each_with_object({}) { |team, map| map[team["name"]] = team; }

    labels_downcase_set = Set.new

    services.each do |service|
      service_name = service["name"]

      # team
      service_team = service["team"]
      raise "'#{service_name}' | unknown team: '#{service_team}''" unless service_team.nil? || team_map[service_team]

      # label
      service_label = service["label"]
      service_label_downcase = service_label.downcase
      raise "'#{service_label}' | duplicated labels found in service catalog. Label field must be unique (case insensitive)" if labels_downcase_set.include?(service_label_downcase)

      labels_downcase_set << service_label_downcase

      # owner
      service_owner = service["owner"]
      raise "'#{service_name}' | unknown owner: '#{service_owner}''" unless service_owner.nil? || team_map[service_owner]
    end
  end
end

begin
  ValidateServiceMappings.new.validate if __FILE__ == $PROGRAM_NAME
rescue StandardError => e
  warn [e.message, *e.backtrace].join("\n")
  exit 1
end
