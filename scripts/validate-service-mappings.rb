#!/usr/bin/env ruby
# frozen_string_literal: true
require 'yaml'
require_relative '../lib/jsonnet_wrapper'

# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/AbcSize
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
    tiers = service_catalog["tiers"]
    services = service_catalog["services"]

    raise "Service catalog must contain one or more teams" unless teams && !teams.empty?
    raise "Service catalog must contain one or more tiers" unless tiers && !tiers.empty?

    team_map = teams.each_with_object({}) { |team, map| map[team["name"]] = team; }
    tier_map = tiers.each_with_object({}) { |tier, map| map[tier["name"]] = tier; }

    teams.each do |team|
      # name
      team_name = team["name"]
      raise "'#{team_name}' | team.name field must be string" unless team_name.is_a? String

      slack_alerts_channel = team["slack_alerts_channel"]
      if slack_alerts_channel
        raise "'#{team_name}' | slack_alerts_channel must be a string" unless slack_alerts_channel.is_a? String
        raise "'#{team_name}' | slack_alerts_channel must not start with a hash" if slack_alerts_channel.start_with?("#")
      end

      stage_group = team["product_stage_group"]
      raise "'#{team_name}' | '#{stage_group}' is not a known stage group" if stage_group && !known_stage_groups.include?(stage_group)
    end

    labels_downcase_set = Set.new

    services.each do |service|
      # name
      service_name = service["name"]
      raise "'#{service_name}' | service.name field must be string" unless service_name.is_a? String

      # tier
      service_tier = service["tier"]
      raise "'#{service_name}' | tier field must be string" unless service_tier.is_a? String
      raise "unknown tier '#{service['tier']}''" unless tier_map[service["tier"]]

      # team (non-mandatory)
      service_team = service["team"]
      if service_team
        raise "'#{service_name}' | team field must be string" unless service_teams.is_a? String
        raise "'#{service_name}' | unknown team: '#{service_team}''" unless team_map[service_team]
      end

      # friendly_name
      friendly_name = service["friendly_name"]
      raise "'#{service_name}' | service.friendly_name field must be string" unless friendly_name.is_a? String

      # label
      service_label = service["label"]
      raise "'#{service_name}' | label field must be string" unless service_label.is_a? String

      service_label_downcase = service_label.downcase
      raise "'#{service_label}' | duplicated labels found in service catalog. Label field must be unique (case insensitive)" if labels_downcase_set.include?(service_label_downcase)

      labels_downcase_set << service_label_downcase

      # Business
      # =========

      # Business requirements are optional for purely technical services
      # overall_sla_weighting
      overall_sla_weighting = service.dig("business", "SLA", "overall_sla_weighting")
      raise "'#{service_name}' | overall_sla_weighting field must be integer" unless overall_sla_weighting.is_a?(Integer) || overall_sla_weighting.nil?

      # Technical
      # =========

      # project
      project = service.dig("technical", "project")
      raise "'#{service_name}' | project field must be list" unless project.is_a?(Array) || project.nil?

      # design
      design_doc = service.dig("technical", "documents", "design")
      raise "'#{service_name}' | design document field must be string" unless design_doc.is_a?(String) || design_doc.nil?

      # architecture
      architecture_doc = service.dig("technical", "documents", "architecture")
      raise "'#{service_name}' | architecture document field must be string" unless architecture_doc.is_a?(String) || architecture_doc.nil?

      # service
      service_doc = service.dig("technical", "documents", "service")
      raise "'#{service_name}' | service document field must be list" unless service_doc.is_a?(Array) || service_doc.nil?

      # security
      security_doc = service.dig("technical", "documents", "security")
      raise "'#{service_name}' | security document field must be string" unless security_doc.is_a?(String) || security_doc.nil?

      # dependencies
      dependencies = service.dig("technical", "dependencies")
      raise "'#{service_name}' | dependencies field must be list" unless dependencies.is_a?(Array) || dependencies.nil?

      dependencies&.each do |dependency|
        raise "'#{service_name}' | dependency value must be string" unless dependency["service"].is_a?(String) || dependency["service"].nil?
      end

      # logging
      logging = service.dig("technical", "logging")
      if logging
        raise "'#{service_name}' | logging field must be list" unless logging.is_a? Array
        raise "service '#{service_name}' requires at least one logging configuration" if logging.empty?

        logging.each do |log|
          raise "'#{service_name}' | log name field must be string" unless log["name"].is_a?(String) || log["name"].nil?
          raise "'#{service_name}' | log permalink field must be string" unless log["permalink"].is_a?(String) || log["permalink"].nil?
        end
      end

      # observability
      # monitors
      monitors = service.dig("observability", "monitors")

      unless monitors.nil? # rubocop:disable Style/Next
        if monitors.key?("grafana_folder")
          grafana_folder = monitors["grafana_folder"]
          raise "'#{service_name}' | grafana_folder field must be string" unless grafana_folder.is_a?(String) || grafana_folder.nil?
        end

        if monitors.key?("primary_grafana_dashboard")
          primary_grafana_dashboard = monitors["primary_grafana_dashboard"]
          raise "'#{service_name}' | primary_grafana_dashboard field must be string" unless primary_grafana_dashboard.is_a?(String) || primary_grafana_dashboard.nil?
          raise "'#{service_name}' | primary_grafana_dashboard is appended to the Grafana base URL so it must be relative" unless primary_grafana_dashboard.nil? || !primary_grafana_dashboard.match(%r{^https?://})
        end

        if monitors.key?("sentry_slug")
          sentry_slug = monitors["sentry_slug"]
          raise "'#{service_name}' | sentry_slug field must be string" unless sentry_slug.is_a?(String) || sentry_slug.nil?
        end
      end
    end
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize
end

begin
  ValidateServiceMappings.new.validate if __FILE__ == $PROGRAM_NAME
rescue StandardError => e
  warn [e.message, *e.backtrace].join("\n")
  exit 1
end
