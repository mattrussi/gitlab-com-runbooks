#! /usr/bin/env ruby
# frozen_string_literal: true

# vi: set ft=ruby :

# -*- mode: ruby -*-

# This script must be ran on a gitaly shard node. It will operate on the
# disk paths taken from a json-formatted file containing an enumeration of
# leftover repositories.
#
# Staging execution:
#
# ssh file-01-stor-gstg.c.gitlab-staging-1.internal
# sudo gitlab-rails runner /var/opt/gitlab/scripts/storage_leftovers.rb --command='ls -d' --dry-run=yes
# sudo gitlab-rails runner /var/opt/gitlab/scripts/storage_leftovers.rb --command='ls -d' --dry-run=no
# sudo gitlab-rails runner /var/opt/gitlab/scripts/storage_leftovers.rb --sum-disk-space --dry-run=no
#
# Production execution:
#
# ssh file-01-stor-gprd.c.gitlab-production.internal
# sudo gitlab-rails runner /var/opt/gitlab/scripts/storage_leftovers.rb --command='ls -d' --dry-run=yes
# sudo gitlab-rails runner /var/opt/gitlab/scripts/storage_leftovers.rb --command='ls -d' --dry-run=no
# sudo gitlab-rails runner /var/opt/gitlab/scripts/storage_leftovers.rb --sum-disk-space --dry-run=no
#

require 'fileutils'
require 'json'
require 'optparse'

begin
  require '/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb'
rescue LoadError => e
  warn "WARNING: #{e.message}"
end

# Storage module
module Storage
  # RepositoryLeftoversOpsScript module
  module RepositoryLeftoversOpsScript
    INVENTORY_TIMESTAMP_FORMAT = '%Y-%m-%d_%H%M%S'
    LOG_TIMESTAMP_FORMAT = '%Y-%m-%d %H:%M:%S'
  end
  # module RepositoryLeftoversOpsScript
end

# Re-open the Storage module to add the Config module
module Storage
  # RepositoryLeftoversOpsScript module
  module RepositoryLeftoversOpsScript
    # Config module
    module Config
      DEFAULTS = {
        dry_run: true,
        repositories_root_dir_path: '/var/opt/gitlab/git-data/repositories',
        hashed_storage_dir_name: '@hashed',
        leftovers_dir_name: 'leftovers.d',
        leftovers_file_name: 'leftover-git-repositories-%<date>s.txt',
        log_level: Logger::INFO,
        env: :production,
        status: '%<index>s of %<total>s; %<percent>.2f%%',
        project_keys: [:id, :disk_path, :repository_storage],
        slice_size: 20
      }.freeze
    end
  end
end

# Re-open the Storage module to add the Logging module
module Storage
  # This module defines logging methods
  module Logging
    def initialize_log
      STDOUT.sync = true
      timestamp_format = ::Storage::RepositoryLeftoversOpsScript::LOG_TIMESTAMP_FORMAT
      log = Logger.new STDOUT
      log.level = Logger::INFO
      log.formatter = proc do |level, t, _name, msg|
        fields = { timestamp: t.strftime(timestamp_format), level: level, msg: msg }
        Kernel.format("%<timestamp>s %-5<level>s %<msg>s\n", **fields)
      end
      log
    end

    def initialize_progress_log
      log = initialize_log
      timestamp_format = ::Storage::RepositoryLeftoversOpsScript::LOG_TIMESTAMP_FORMAT
      log.formatter = proc do |level, t, _name, msg|
        fields = { timestamp: t.strftime(timestamp_format), level: level, msg: msg }
        Kernel.format("\r%<timestamp>s %-5<level>s %<msg>s", **fields)
      end
      log
    end

    def log
      @log ||= initialize_log
    end

    def progress_log
      @progress_log ||= initialize_progress_log
    end

    def dry_run_notice
      log.info '[Dry-run] This is only a dry-run -- write operations will be logged but not executed'
    end

    def debug_command(cmd)
      log.debug "Command: #{cmd}"
      cmd
    end
  end
  # module Logging
end
# module Storage

# Re-open the Storage module to add the CommandLineSupport module
module Storage
  # Support for command line arguments
  module CommandLineSupport
    # OptionsParser class
    class OptionsParser
      Fields = %i[banner dry_run command sum_disk_space verbose version help].freeze
      attr_reader :parser, :options

      def initialize
        @parser = OptionParser.new
        @options = ::Storage::RepositoryLeftoversOpsScript::Config::DEFAULTS.dup
        Fields.each { |method_name| self.method(method_name).call if self.respond_to?(method_name) }
      end

      def banner
        @parser.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"
        @parser.separator ''
        @parser.separator 'Options:'
      end

      def dry_run
        description = 'Show what would have been done; default: yes'
        @parser.on('-d', '--dry-run=[yes/no]', description) do |dry_run|
          @options[:dry_run] = !dry_run.match?(/^(no|false)$/i)
        end
      end

      def command
        @parser.on('--command=command', 'Command to invoke on a leftover git repository') do |str|
          @options[:command] = str
        end
      end

      def sum_disk_space
        @parser.on('--sum-disk-space', 'Command to invoke on a leftover git repository') do
          @options[:sum_disk_space] = true
        end
      end

      def verbose
        @parser.on('-v', '--verbose', 'Increase logging verbosity') do
          @options[:log_level] -= 1
        end
      end

      def version
        @parser.on_tail('-v', '--version', 'Show version') do
          puts "#{$PROGRAM_NAME} version 1"
          exit
        end
      end

      def help
        @parser.on_tail('-?', '--help', 'Show this message') do
          puts @parser
          exit
        end
      end
    end
    # class OptionsParser

    def parse(args = ARGV, file_path = ARGF)
      opt = OptionsParser.new
      args.push('-?') if args.empty?
      opt.parser.parse!(args)
      opt.options
    rescue OptionParser::InvalidArgument, OptionParser::InvalidOption,
           OptionParser::MissingArgument, OptionParser::NeedlessArgument => e
      puts e.message
      puts opt.parser
      exit
    rescue OptionParser::AmbiguousOption => e
      abort e.message
    end
  end
  # module CommandLineSupport
end
# module Storage

# Re-open the Storage module to define the Helpers module
module Storage
  # Helper methods
  module Helpers
    ApplicationError = Class.new(StandardError)
    UserError = Class.new(StandardError)
    DENOMINATION_CONVERSIONS = {
      'Bytes': 1024,
      'KB': 1024 * 1024,
      'MB': 1024 * 1024 * 1024,
      'GB': 1024 * 1024 * 1024 * 1024,
      'TB': 1024 * 1024 * 1024 * 1024 * 1024
    }.freeze

    def human_friendly_filesize(bytes)
      DENOMINATION_CONVERSIONS.each_pair do |e, s|
        return [(bytes.to_f / (s / 1024)).round(2), e].join(' ') if bytes < s
      end
    end

    def percentage_of_total_disk_space(size, total_disk_space)
      return 0 if total_disk_space <= 0

      ((size / total_disk_space.to_f) * 100).round(2)
    end

    def parse_timestamp(path, regexp)
      regexp.match(path) { |m| Time.at(m.captures.first.to_i).utc } || UNIX_EPOCH
    end
  end
end

# Re-open the Storage module to define the RepositoryLeftoversOperator class
module Storage
  # The RepositoryLeftoversOperator class
  class RepositoryLeftoversOperator
    include ::Storage::Helpers
    include ::Storage::Logging
    attr_reader :options, :leftovers_dir_path
    def initialize(options)
      @options = options
      log.level = @options[:log_level]
      init_paths
    end

    def init_paths
      @leftovers_dir_path = File.join(__dir__, options[:leftovers_dir_name])
      FileUtils.mkdir_p(leftovers_dir_path) unless File.directory?(leftovers_dir_path)
    end

    def timestamped_file_name(file_name)
      format(
        file_name,
        date: Time.now.strftime(::Storage::RepositoryLeftoversOpsScript::INVENTORY_TIMESTAMP_FORMAT))
    end

    def load_latest_leftovers
      leftovers_files = Dir.new(leftovers_dir_path).children
      return [] if leftovers_files.empty?

      latest_leftovers_file_path = File.join(leftovers_dir_path, leftovers_files.max)
      return [] unless File.exist?(latest_leftovers_file_path)

      IO.readlines(latest_leftovers_file_path, chomp: true)
    end

    def latest_leftovers
      leftovers = load_latest_leftovers.collect { |line| JSON.parse(line, symbolize_names: true) }
      log.info "Found #{leftovers.length} known leftover git repositories"
      leftovers
    end

    def update_status(iteration, total)
      status = format(
        options[:status],
        index: iteration,
        total: total,
        percent: ((iteration / total.to_f) * 100).round(2))
      status << "\n" if log.level == Logger::DEBUG || options[:dry_run]
      progress_log.info(status)
    end

    def each_with_status(enumerable)
      enumerable.each_with_index do |element, iteration|
        yield element
        update_status(iteration, enumerable.length)
      end
      $stdout.write("\n")
    end

    def operate(command, repositories)
      raise UserError, 'No command given; terminating' if command.nil? || command.empty?
      repositories_root_dir_path = options[:repositories_root_dir_path]
      each_with_status(repositories) do |repository|
        disk_path = repository[:disk_path]
        raise ApplicationError, "Encountered bad git repository disk path!" if disk_path.nil? || disk_path.empty?
        repository_path = File.join(repositories_root_dir_path, disk_path + '.git')
        cmd = [command, repository_path].join(' ')
        if options[:dry_run]
          log.info "[Dry-run] Would have executed command: #{cmd}"
        else
          log.debug "Executing command: #{cmd}"
          result = `#{cmd}`.strip
          yield result unless result.empty?
        end
      end
    end

    def sum_disk_space(command = 'du -xs')
      results = []
      operate(command, latest_leftovers) { |result| results << result }
      total_disk_space = results.sum do |result|
        disk_space_kilobytes = result.split(/\s+/).first.to_i
        disk_space_kilobytes * 1_000 # bytes
      end
      log.info "Estimated disk space which would be reclaimed by deleting leftover git " \
        "repositories: #{human_friendly_filesize(total_disk_space)}"
    end

    def run_command(command)
      results = []
      operate(command, latest_leftovers) { |result| results << result }
      results.each do |result|
        log.info result.to_s
      end
    end
  end
  # class RepositoryLeftoversOperator
end
# module Storage

# Re-open the Storage module to add RepositoryLeftoversOpsScript module
module Storage
  # RepositoryLeftoversOpsScript module
  module RepositoryLeftoversOpsScript
    include ::Storage::Logging
    include ::Storage::CommandLineSupport

    def main(args = parse(ARGV, ARGF))
      dry_run_notice if args[:dry_run]
      operator = ::Storage::RepositoryLeftoversOperator.new(args)
      return operator.sum_disk_space if args[:sum_disk_space]
      operator.run_command(args[:command])
    rescue StandardError => e
      log.error("Unexpected error: #{e}")
      e.backtrace.each { |t| log.error(t) }
      abort
    rescue SystemExit
      exit
    rescue Interrupt => e
      $stderr.write "\r\n#{e.class}\n"
      $stderr.flush
      $stdin.echo = true
      exit 0
    end
  end
  # RepositoryLeftoversOpsScript module
end
# module Storage

# Anonymous object avoids namespace pollution
Object.new.extend(::Storage::RepositoryLeftoversOpsScript).main if $PROGRAM_NAME == __FILE__
