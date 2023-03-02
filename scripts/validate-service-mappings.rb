#!/usr/bin/env ruby
# frozen_string_literal: true
require 'yaml'
require_relative '../lib/jsonnet_wrapper'

# For basic type validations, use JSON Schema in https://gitlab.com/gitlab-com/runbooks/-/blob/master/services/service-catalog-schema.json
class ValidateServiceMappings
  DEFAULT_KNOWN_STAGE_GROUPS_PATH = File.join(__dir__, "..", "services", "stage-group-mapping.jsonnet")
  DEFAULT_RAW_CATALOG_PATH = File.join(__dir__, "..", "services", "raw-catalog.jsonnet")

  def initialize(raw_catalog_path = DEFAULT_RAW_CATALOG_PATH, known_stage_groups_path = DEFAULT_KNOWN_STAGE_GROUPS_PATH)
    @raw_catalog_path = raw_catalog_path
    @known_stage_groups_path = known_stage_groups_path
  end

  def validate
    known_stage_groups = JsonnetWrapper.new.parse(@known_stage_groups_path).keys
    service_catalog = JsonnetWrapper.new.parse(@raw_catalog_path)

    teams = service_catalog["teams"]
    services = service_catalog["services"]

    team_map = teams.each_with_object({}) { |team, map| map[team["name"]] = team; }

    teams.each do |team|
      team_name = team["name"]

      # product_stage_group
      stage_group = team["product_stage_group"]
      raise "'#{team_name}' | '#{stage_group}' is not a known stage group" if stage_group && !known_stage_groups.include?(stage_group)
    end

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
