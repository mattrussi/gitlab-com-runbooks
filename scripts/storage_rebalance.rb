#! /usr/bin/env ruby
# frozen_string_literal: true

# vi: set ft=ruby :

# -*- mode: ruby -*-

# Execution:
#
#    sudo su - root
#    mkdir -p /var/opt/gitlab/scripts
#    cd /var/opt/gitlab/scripts
#    curl --silent --remote-name https://gitlab.com/gitlab-com/runbooks/raw/master/scripts/storage_rebalance.rb
#    chmod +x storage_rebalance.rb
#    export PRIVATE_TOKEN=CHANGEME
#
# Staging example:
#
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file01 --target-file-server=nfs-file09 --staging --count
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file01 --target-file-server=nfs-file09 --staging --count
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file01 --target-file-server=nfs-file09 --staging --max-failures=200 --validate-size --refresh-stats
#
# Production examples:
#
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file36 --target-file-server=nfs-file46 --wait=10800 --max-failures=1 --validate-size --validate-checksum --refresh-stats
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file36 --target-file-server=nfs-file46 --count
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file25 --target-file-server=nfs-file36
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file34 --target-file-server=nfs-file42 --project=13007013 | tee /var/opt/gitlab/scripts/logs/nfs-file42.migration.$(date +%Y-%m-%d_%H%M).log
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=yes --current-file-server=nfs-file34 --target-file-server=nfs-file42 | tee /var/opt/gitlab/scripts/logs/nfs-file42.migration.$(date +%Y-%m-%d_%H%M).log
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verbose --dry-run=no --move-amount=10 --current-file-server=nfs-file27 --target-file-server=nfs-file38 --skip=9271929 | tee /var/opt/gitlab/scripts/logs/nfs-file38.migration.$(date +%Y-%m-%d_%H%M).log
#
# Verify the migration status of previously logged project migrations:
#
#    gitlab-rails runner /var/opt/gitlab/scripts/storage_rebalance.rb --verify-only
#
# Logs may be reviewed:
#
#    export logd=/var/log/gitlab/storage_migrations; for f in `ls -t ${logd}`; do ls -la ${logd}/$f && cat ${logd}/$f; done
#

require 'csv'
require 'date'
require 'fileutils'
require 'json'
require 'io/console'
require 'logger'
require 'optparse'
require 'uri'

begin
  require '/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb'
rescue LoadError => e
  warn e.message
end

LOG_TIMESTAMP_FORMAT = '%Y-%m-%d %H:%M:%S'

def initialize_log
  STDOUT.sync = true
  log = Logger.new(STDOUT, level: Logger::INFO)
  log.formatter = proc do |level, t, name, msg|
    fields = { timestamp: t.strftime(LOG_TIMESTAMP_FORMAT), level: level, msg: msg }
    format("%<timestamp>s %-5<level>s %<msg>s\n", **fields)
  end
  log
end

class Object
  def log
    @log ||= initialize_log
  end
end

module Storage
  ISO8601_FRACTIONAL_SECONDS_LENGTH = 3

  NodeConfiguration = {}.freeze
  NodeConfiguration.merge! ::Gitlab.config.repositories.storages if defined? ::Gitlab

  class NoCommits < StandardError; end
  class MigrationTimeout < StandardError; end
  class CommitsMismatch < StandardError; end
  class ChecksumsMismatch < StandardError; end
  class RepositorySizesMismatch < StandardError; end

  Options = {
    dry_run: true,
    log_level: Logger::INFO,
    api_endpoints: {
      staging: 'https://staging.gitlab.com/api/v4/projects/%{project_id}/repository/commits',
      production: 'https://gitlab.com/api/v4/projects/%{project_id}/repository/commits'
    },
    move_amount: 0,
    timeout: 10800,
    max_failures: 3,
    clauses: {
      delete_error: nil,
      pending_delete: false,
      project_statistics: {commit_count: 1..Float::INFINITY},
      mirror: false,
    },
    count: false,
    print_largest: false,
    verify_only: false,
    validate_checksum: false,
    validate_size: false,
    list_nodes: false,
    projects: [],
    black_list: [],
    refresh_statistics: false,
    include_mirrors: false,
    stats: [:commit_count, :storage_size, :repository_size],
    group: nil,
    env: :production,
    logdir_path: '/var/log/gitlab/storage_migrations',
    migration_logfile_name: 'migrated_projects_%{date}.log',
  }.freeze

  def resembles_integer?(s)
    s.to_s.match? /\A\d+\Z/
  end

  def parse_args
    Options[:projects].concat CSV.new(ARGF).to_a if (!STDIN.tty?) && (!STDIN.closed?)
    ARGV << '-?' if ARGV.empty?
    opt = OptionParser.new
    opt.banner = "Usage: #{$PROGRAM_NAME} [options] --current-file-server <servername> --target-file-server <servername>"
    opt.separator ''
    opt.separator 'Options:'

    opt.on_head('--current-file-server=<SERVERNAME>', String, 'Source storage node server') do |server|
      Options[:current_file_server] = server
    end

    opt.on_head('--target-file-server=<SERVERNAME>', String, 'Destination storage node server') do |server|
      Options[:target_file_server] = server
    end

    opt.on('-d', '--dry-run=[yes/no]', 'Show what would have been done; default: yes') do |dry_run|
      Options[:dry_run] = !(dry_run =~ /^(no|false)$/i)
    end

    opt.on('--list-nodes', 'List all known repository storage nodes') do |list_nodes|
      Options[:list_nodes] = true
    end

    opt.on('--projects=<project_id,...>', Array, 'Select specific projects to migrate') do |project_identifiers|
      Options[:projects] ||= []
      if project_identifiers.respond_to?(:all?) && project_identifiers.all? { |s| resembles_integer? s }
        Options[:projects].concat project_identifiers.map(&:to_i).delete_if { |i| i <= 0 }
      else
        raise OptionParser::InvalidArgument.new("Argument given for --projects must be a list of one or more integers")
      end
    end

    opt.on('--csv=<file_path>', 'Absolute path to CSV file enumerating projects ids') do |file_path|
      unless File.exist? file_path
        message = "Argument given for --csv must be an absolute path to an existing file"
        raise OptionParser::InvalidArgument.new(message)
      end

      Options[:projects] ||= []
      begin
        project_identifiers = IO.readlines(file_path, chomp: true)
        if project_identifiers.respond_to?(:all?) && project_identifiers.all? { |s| resembles_integer? s }
          Options[:projects].concat project_identifiers.map(&:to_i).delete_if { |i| i <= 0 }
        else
          message = "Argument given for --csv must be an absolute path to a file containing a " \
            "list of one or more integers"
          raise OptionParser::InvalidArgument.new(message)
        end
      rescue StandardError => e
        abort e.message
      end
    end

    opt.on('--skip=<project_id,...>', Array, 'Skip specific project(s)') do |project_identifiers|
      Options[:black_list] ||= []
      if project_identifiers.respond_to?(:all?) && project_identifiers.all? { |s| resembles_integer? s }
        Options[:black_list].concat project_identifiers.map(&:to_i).delete_if { |i| i <= 0 }
      else
        raise OptionParser::InvalidArgument, "Argument given for --skip must be a list of one or more integers"
      end
    end

    opt.on('-r', '--refresh-stats', 'Refresh all project statistics; WARNING: ignores --dry-run') do |refresh_statistics|
      Options[:refresh_statistics] = true
    end

    opt.on('-N', '--count', 'How many projects are on current file server') do |count|
      Options[:count] = true
    end

    opt.on('-L', '--print-largest', 'Find the largest project repository on current file server') do |print_largest|
      Options[:print_largest] = true
    end

    opt.on('-m', '--move-amount=<N>', Integer, "Gigabytes of repo data to move; default: #{Options[:move_amount]}, or largest single repo if 0") do |move_amount|
      abort 'Size too large' if move_amount > 16_000
      Options[:move_amount] = (move_amount * 1024 * 1024 * 1024) # Convert given gigabytes to bytes
    end

    opt.on('-w', '--wait=<N>', Integer, "Timeout in seconds for migration completion; default: #{Options[:timeout]}") do |wait|
      Options[:timeout] = wait
    end

    opt.on('-V', '--verify-only', 'Verify that projects have successfully migrated') do |verify_only|
      Options[:verify_only] = true
    end

    opt.on('-C', '--validate-checksum', 'Validate project checksum is constant post-migration') do |checksum|
      Options[:validate_checksum] = true
    end

    opt.on('-S', '--validate-size', 'Validate project repository size is constant post-migration') do |checksum|
      Options[:validate_size] = true
    end

    opt.on('-f', '--max-failures=<N>', Integer, "Maximum failed migrations; default: #{Options[:max_failures]}") do |failures|
      Options[:max_failures] = failures
    end

    opt.on('--group=<GROUPNAME>', String, 'Filter projects by group') do |group|
      Options[:group] = group
    end

    opt.on('-M', '--include-mirrors', 'Include mirror repositories') do |include_mirrors|
      Options[:include_mirrors] = true
    end

    opt.on('--staging', 'Use the staging environment') do |env|
      Options[:env] = :staging
    end

    opt.on('-v', '--verbose', 'Increase logging verbosity') do |verbose|
      Options[:log_level] -= 1
    end
    opt.on_tail('-?', '--help', 'Show this message') do
      puts opt
      exit
    end
    begin
      args = opt.order!(ARGV) {}
      opt.parse!(args)
    rescue OptionParser::InvalidArgument, OptionParser::InvalidOption,
           OptionParser::NeedlessArgument => e
      puts e.message
      puts opt
      exit
    rescue OptionParser::AmbiguousOption => e
      abort e.message
    end
    Options
  end

  def largest_denomination(bytes)
    if bytes.to_gb > 0
      "#{bytes.to_gb} GB"
    elsif bytes.to_mb > 0
      "#{bytes.to_mb} MB"
    elsif bytes.to_kb > 0
      "#{bytes.to_kb} KB"
    else
      "#{bytes} Bytes"
    end
  end

  class Rebalancer
    MIGRATION_TIMESTAMP_FORMAT = '%Y-%m-%d_%H%M%S'
    include ::Storage
    def initialize
      log.level = Options[:log_level]
      logfile_path = configure_project_migration_logging

      log.info "Moving projects"
      log.info "From: #{Options[:current_file_server]}"
      log.info "To:   #{Options[:target_file_server]}"
      log.debug "Project migration validation timeout: #{Options[:timeout]} seconds"
      log.debug "Migration log file path: #{logfile_path}"
    end

    def configure_project_migration_logging
      fields = { date: Time.now.strftime(MIGRATION_TIMESTAMP_FORMAT) }
      logfile_name = format(Options[:migration_logfile_name], **fields)
      logdir_path = Options[:logdir_path]
      FileUtils.mkdir_p logdir_path
      logfile_path = File.join(logdir_path, logfile_name)
      FileUtils.touch logfile_path
      @migration_log = Logger.new(logfile_path, level: Logger::INFO)
      @migration_log.formatter = proc { |level, t, name, msg| "#{msg}\n" }
      logfile_path
    rescue StandardError => e
      log.error "Failed to configure logging: #{e.message}"
      exit
    end

    def migration_errors
      @errors ||= []
    end

    def get_storage_node_hostname(storage_node_name)
      hostname = nil
      url = NodeConfiguration.fetch(storage_node_name, {}).fetch('gitaly_address', nil)
      if url
        uri = URI.parse(url)
        hostname = uri.host
      end
      hostname
    end

    def get_commit_id(project_id)
      endpoints = Options[:api_endpoints]
      environment = Options[:env]
      url = endpoints.include?(environment) ? endpoints[environment] : endpoints[:production]
      abort "No api endpoint url is configured" if url.nil? || url.empty?
      url = format(url, project_id: project_id)
      uri = URI(url)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri.request_uri)
      request['Private-Token'] = Options.fetch(:private_token) do
        abort "A private API token is required."
      end

      log.debug "[The following curl command is for external diagnostic purposes only:]"
      log.debug "curl --verbose --silent '#{url}' --header \"Private-Token: ${PRIVATE_TOKEN}\""
      response = http.request(request)

      payload = JSON.parse(response.body)
      log.debug "Response code: #{response.code}"
      if payload.empty?
        log.debug "Response payload: []"
      elsif payload.respond_to? :first
        log.debug "Response payload sample:"
        log.debug JSON.pretty_generate(payload.first)
      else
        log.debug "Response payload:"
        log.debug JSON.pretty_generate(payload)
      end

      commit_id = nil
      if response.code.to_i == 200 && !payload.empty?
        first_commit = payload.first
        commit_id = first_commit['id']
      elsif payload.include? 'message'
        log.error "Error: #{payload['message']}"
      end

      commit_id
    end

    def wait_for_repository_storage_update(project)
      start = Time.now.to_i
      i = 0
      timeout = Options[:timeout]
      while project.repository_read_only?
        sleep 1
        project.reload
        print '.'
        i += 1
        print "\n" if i % 80 == 0
        elapsed = Time.now.to_i - start
        next unless elapsed >= timeout

        print "\n"
        log.warn ""
        log.warn "Timed out up waiting for project id: #{project.id} to move: #{elapsed} seconds"
        break
      end
      print "\n"
      if project.repository_storage == Options[:target_file_server]
        log.info "Success moving project id:#{project.id}"
      else
        log.warn "Project id: #{project.id} still reporting incorrect file server"
      end
    end

    def migrate(project)
      log.info('='*72)
      log.info "Migrating project id: #{project.id}"
      log.info "  Size: ~#{largest_denomination(project.statistics.repository_size)}"
      log.debug "  Name: #{project.name}"
      log.debug "  Group: #{project.group.name}" unless project.group.nil?
      log.debug "  Storage: #{project.repository_storage}"
      log.debug "  Path: #{project.disk_path}"
      if Options[:refresh_statistics]
        log.debug "Pre-refresh statistics:"
        Options[:stats].each do |stat|
          log.debug "  #{stat.capitalize}: #{project.statistics[stat]}"
        end
        project.statistics.refresh!(only: Options[:stats])
        log.debug "Post-refresh statistics:"
      else
        log.debug "Project statistics:"
      end
      Options[:stats].each do |stat|
        log.debug "  #{stat.capitalize}: #{project.statistics[stat]}"
      end

      original_commit_id = get_commit_id(project.id)
      raise NoCommits, "Could not obtain any commits for project id #{project.id}" if original_commit_id.nil?

      project.repository.expire_exists_cache
      original_checksum = project.repository.checksum if Options[:validate_checksum]
      original_repository_size = project.statistics[:repository_size] if Options[:validate_size]

      log_artifact = {
        id: project.id,
        path: project.disk_path,
        source: get_storage_node_hostname(project.repository_storage),
        destination: get_storage_node_hostname(Options[:target_file_server])
      }

      if Options[:dry_run]
        log.info "[Dry-run] Would have moved project id: #{project.id}"
        @migration_log.info log_artifact.merge({ dry_run: true }).to_json
      else
        log.info "Scheduling migration for project id: #{project.id} to #{Options[:target_file_server]}"
        project.change_repository_storage(Options[:target_file_server])
        project.save

        wait_for_repository_storage_update(project)
        post_migration_project = Project.find_by(id: project.id)

        if post_migration_project.repository_storage != Options[:target_file_server]
          raise MigrationTimeout, "Timed out waiting for migration of " \
            "project id: #{post_migration_project.id}"
        end

        log.debug "Refreshing all statistics for project id: #{post_migration_project.id}"
        post_migration_project.statistics.refresh!

        log.info "Validating project integrity by comparing latest commit " \
          "identifers before and after"
        current_commit_id = get_commit_id(post_migration_project.id)
        log.debug "Original commit id: #{original_commit_id}, current commit id: " \
          "#{current_commit_id}"
        if original_commit_id != current_commit_id
          raise CommitsMismatch, "Current commit id #{current_commit_id} " \
            "does not match original commit id #{original_commit_id}"
        end

        if Options[:validate_checksum]
          log.info "Validating project integrity by comparing checksums " \
            "before and after"
          post_migration_project.repository.expire_exists_cache
          current_checksum = post_migration_project.repository.checksum
          log.debug "Original checksum: #{original_checksum}, current checksum: " \
            "#{current_checksum}"
          if original_checksum != current_checksum
            raise ChecksumsMismatch, "Current checksum #{current_checksum} " \
              "does not match original checksum #{original_checksum}"
          end
        end

        if Options[:validate_size]
          log.info "Validating project integrity by comparing repository size " \
            "before and after"
          current_repository_size = post_migration_project.statistics[:repository_size]
          log.debug "Original repository size: #{original_repository_size}, current size: " \
            "#{current_repository_size}"
          if original_repository_size != current_repository_size
            raise RepositorySizesMismatch, "Current repository size #{current_repository_size} " \
              "does not match original repository size #{original_repository_size}"
          end
        end

        log.info "Migrated project id: #{post_migration_project.id}"
        log.debug "  Name: #{post_migration_project.name}"
        log.debug "  Storage: #{post_migration_project.repository_storage}"
        log.debug "  Path: #{post_migration_project.disk_path}"
        log_artifact[:date] = DateTime.now.iso8601(ISO8601_FRACTIONAL_SECONDS_LENGTH)
        @migration_log.info log_artifact.to_json
      end
    end

    def get_namespace(group)
      namespace_id = Namespace.find_by(path: group)
      raise "No such namespace" if namespace_id.nil?
      namespace_id
    rescue StandardError => e
      log.fatal "Error finding given group name '#{group}': #{e.message}"
      abort
    end

    def namespace_filter(clauses, group)
      return clauses if group.nil? || group.empty?

      log.info "Filtering projects by group: #{group}"
      clauses.merge(namespace_id: get_namespace(group))
    end

    def with_timeout(interval_in_seconds)
      ActiveRecord::Base.connection.execute "SET statement_timeout = #{interval_in_seconds}"
      yield
    end

    def self.count
      clauses = namespace_filter(Options[:clauses].dup, Options[:group])
      clauses.merge!(repository_storage: Options[:current_file_server])
      clauses.delete(:mirror) if Options[:include_mirrors]
      query = Project.joins(:statistics).where(**clauses)
      Project.transaction do
        with_timeout(600000) { query.size }
      end
    end

    def get_project_ids(limit=0, project_ids=[])
      clauses = namespace_filter(Options[:clauses].dup, Options[:group])
      clauses.merge!(repository_storage: Options[:current_file_server])
      unless project_ids.empty?
        # The user specified one or more project identifiers;
        # So don't filter out mirrors
        clauses.delete(:mirror)
        clauses.merge!(id: project_ids)
      end
      clauses.delete(:mirror) if Options[:include_mirrors]
      # Query all projects on the current file server that have not failed
      # any previous delete operations, sort by size descending,
      # then sort by last activity date ascending in order to select the
      # most idle and largest projects first.
      query = Project.joins(:statistics).
        where(**clauses).
        order('project_statistics.repository_size DESC').
        order('last_activity_at ASC')
      query = query.limit(limit) if limit > 0
      project_identifiers = Project.transaction do
        with_timeout(600000) { query.pluck(:id) }
      end
      black_list = Options[:black_list]
      return project_identifiers if black_list.empty?

      log.debug "Skipping projects: #{black_list}"
      project_identifiers - black_list
    end

    def move_projects(project_ids, min_amount=Options[:move_amount])
      total = 0
      project_ids.each do |project_id|
        project = Project.find_by(id: project_id)
        begin
          migrate(project)
          total += project.statistics.repository_size
        rescue NoCommits => e
          migration_errors << { project_id: project_id, message: e.message }
          log.error "Error: #{e}"
          log.warn "Skipping migration"
        rescue CommitsMismatch => e
          migration_errors << { project_id: project_id, message: e.message }
          log.error "Failed to validate integrity of project id: #{project.id}"
          log.error "Error: #{e}"
          log.warn "Skipping migration"
        rescue ChecksumsMismatch => e
          migration_errors << { project_id: project_id, message: e.message }
          log.error "Failed to validate integrity of project id: #{project.id}"
          log.error "Error: #{e}"
          log.warn "Skipping migration"
        rescue RepositorySizesMismatch => e
          migration_errors << { project_id: project_id, message: e.message }
          log.error "Failed to validate integrity of project id: #{project.id}"
          log.error "Error: #{e}"
          log.warn "Skipping migration"
        rescue MigrationTimeout => e
          migration_errors << { project_id: project_id, message: e.message }
          log.error "Timed out migrating project id: #{project.id}"
          log.error "Error: #{e}"
          log.warn "Skipping migration"
        rescue StandardError => e
          migration_errors << { project_id: project_id, message: e.message }
          log.error "Unexpected error migrating project id #{project.id}: #{e}"
          e.backtrace.each { |t| log.error t }
          log.warn "Skipping migration"
        end
        if migration_errors.length > Options[:max_failures]
          log.error "Failed too many times"
          break
        end
        break if min_amount > 0 && total > min_amount
      end
      total = largest_denomination(total)
      if Options[:dry_run]
        log.info "[Dry-run] Would have processed #{total} of data"
      else
        log.info "Processed #{total} of data"
      end
    end

    def print_largest_project
      project_id = get_project_ids(limit=1).first
      project = Project.find_by(id: project_id)
      log.info "Largest project on #{Options[:current_file_server]}: #{project.id}"
      log.info "  Name: #{project.name}"
      log.info "  Size: ~#{largest_denomination(project.statistics.repository_size)}"
    rescue StandardError => e
      log.fatal "Failed to get largest project: #{e.message}"
      abort
    end

    def rebalance
      project_identifiers = Options[:projects]
      log.debug "Projects to migrate: #{project_identifiers}"
      move_amount_bytes = Options[:move_amount]
      if !project_identifiers.empty?
        project_identifiers = get_project_ids(
          limit=project_identifiers.length,
          project_ids=project_identifiers)
        abort 'No valid project identifiers were given' if project_identifiers.empty?
      elsif move_amount_bytes.zero?
        log.info 'Option --move-amount not specified, will only move 1 project...'
        project_identifiers = [ get_project_ids(limit=1) ]
      else
        log.info "Will move at least #{move_amount_bytes.to_gb} GB worth of data"
        project_identifiers = get_project_ids()
      end
    
      move_projects(project_identifiers)

      log.info('='*72)
      log.info "Finished migrating projects from #{Options[:current_file_server]} to " \
        "#{Options[:target_file_server]}"
      if migration_errors.length > 0
        log.error "Encountered #{migration_errors.length} errors:"
        log.error JSON.pretty_generate(migration_errors)
      else
        log.info "No errors encountered during migration"
      end
    end
  end
  # class Rebalancer

  class Verifier
    include ::Storage

    def get_migrated_project_logs(log_file_paths)
      moved_projects_log_entries = []

      log_file_paths.each do |path|
        log.debug "Extracting project migration logs from: #{path}"
        File.readlines(path).each do |line|
          line.chomp!
          log.debug "Migration log entry: #{line}"
          moved_project = JSON.parse(line, symbolize_names: true)
          moved_projects_log_entries << moved_project unless moved_project[:dry_run]
        end
      end

      moved_projects_log_entries
    end

    def verify
      logdir_path = Options[:logdir_path]
      logfile_name = format(Options[:migration_logfile_name], date: '*')
      log_file_paths = Dir[File.join(logdir_path, logfile_name)].sort

      moved_projects = get_migrated_project_logs(log_file_paths)

      project_identifiers = moved_projects.map { |project| project[:id] }
      Project.find(project_identifiers).each do |project|
        if project.repository_read_only?
          log.info "The repository for project id #{project.id} is still marked read-only on storage node #{project.repository_storage}"
        else
          log.info "The repository for project id #{project.id} appears to have successfully migrated to #{project.repository_storage}"
        end
      end
      log.info "All logged project repository migrations are accounted for"
    end
  end # class Verifier

  def password_prompt(prompt = 'Enter private API token: ')
    $stdout.write(prompt)
    $stdout.flush
    $stdin.noecho(&:gets).chomp
  ensure
    $stdin.echo = true
    $stdout.write "\r" + (' ' * prompt.length)
    $stdout.ioflush
  end

  def gitaly_address(storage_node_name)
    NodeConfiguration.fetch(storage_node_name, {}).fetch('gitaly_address', nil)
  end

  def main
    args = parse_args
    log.level = args[:log_level]
    log.debug "[Dry-run] This is only a dry-run -- write operations will be logged but not " \
      "executed" if args[:dry_run]

    source_storage_node = args[:current_file_server]
    destination_storage_node = args[:target_file_server]

    if Options[:verify_only]
      verifier = Verifier.new
      verifier.verify
      exit
    end
    if args[:list_nodes]
      NodeConfiguration.keys.uniq.sort.each do |repository_storage_node|
        gitaly_address = NodeConfiguration[repository_storage_node]['gitaly_address']
        log.info "#{repository_storage_node}: #{gitaly_address}"
      end
      exit
    end
    if source_storage_node && args[:count]
      log.info "Movable projects stored on #{source_storage_node}: #{Rebalancer.count}"
      exit
    end
    if source_storage_node.nil? || destination_storage_node.nil?
      abort "Missing arguments. Use #{$PROGRAM_NAME} --help to see the list of arguments available"
    end
    if gitaly_address(source_storage_node).nil? || gitaly_address(destination_storage_node).nil?
      abort "Missing gitlab-rails configuration"
    end
    if gitaly_address(source_storage_node) == gitaly_address(destination_storage_node)
      abort "Given destination file storage node must not have the same gitaly address as the source"
    end

    rebalancer = Rebalancer.new
    if source_storage_node && args[:print_largest]
      rebalancer.print_largest_project
      exit
    end

    private_token = ENV.fetch('PRIVATE_TOKEN', nil)
    if private_token.nil? || private_token.empty?
      log.warn "No PRIVATE_TOKEN variable set in environment"
      private_token = password_prompt
      abort "Cannot proceed without a private API token." if private_token.empty?
    end

    Options.store(:private_token, private_token)
    rebalancer.rebalance
  rescue SystemExit
    exit
  rescue Interrupt => e
    $stdout.write "\r\n#{e.class}\n"
    $stdout.flush
    $stdin.echo = true
    exit 0
  end
end

Object.new.extend(Storage).main if $PROGRAM_NAME == __FILE__
