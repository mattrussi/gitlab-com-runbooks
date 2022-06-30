#! /usr/bin/env ruby
# frozen_string_literal: false

# vi: set ft=ruby :
# -*- mode: ruby -*-

# This script must be ran on a console node
#
# Example invocation:
#
#    sudo gitlab-rails runner /var/opt/gitlab/scripts/user_creator.rb --dry-run=yes
#

require 'date'
require 'json'
require 'optparse'
require 'securerandom'
require 'uri'

begin
  require '/opt/gitlab/embedded/service/gitlab-rails/config/environment'
rescue LoadError => e
  warn "WARNING: #{e.message}"
end

# Script module
module Script
  UserError = Class.new(StandardError)

  # UserCreatorScript module
  module UserCreatorScript
    # openssl rand -base64 4096 | tr -dc a-z0-9 | head -c64
    IDENTIFIER = 'doyn1txrke7gsioh7h736ggvezzo3v92jrwj9ag701av15c4sbf340lzkqq1wyhg'.freeze
    PATH_OF_THIS_SCRIPT = File.expand_path(__dir__)

    module_function

    # Config module
    def config
      @config ||= {
        dry_run: true,
        number_of_users: 1,
        teardown: false,
        log_level: Logger::INFO,
        env: :staging,
        user_email_template: 'nnelson+test-%<script_identifier>s-user-%<iteration>s@gitlab.com',
        password: SecureRandom.hex.slice(0, 16),
        namespace_template: 'test-%<script_identifier>s',
        user_first_and_last_name: 'Test User',
        username_template: 'nnelson-test-%<script_identifier>s-user-%<iteration>s',
        dry_run_pattern: /^(n|no|false)$/,
        group_name_template: 'nnelson-test-%<script_identifier>s-group'
      }
    end
  end
end

# Re-open the Script module to add the Logging module
module Script
  # This module defines logging methods
  module Logging
    LOG_TIMESTAMP_FORMAT = '%Y-%m-%d %H:%M:%S'.freeze

    def initialize_log
      $stdout.sync = true
      timestamp_format = ::Script::Logging::LOG_TIMESTAMP_FORMAT
      log = Logger.new $stdout
      log.level = Logger::INFO
      log.formatter = proc do |level, t, _name, msg|
        fields = { timestamp: t.strftime(timestamp_format), level: level, msg: msg }
        Kernel.format("%<timestamp>s %-5<level>s %<msg>s\n", **fields)
      end
      log
    end

    def initialize_progress_log
      log = initialize_log
      timestamp_format = ::Script::Logging::LOG_TIMESTAMP_FORMAT
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
# module Script

# Re-open the Script module to add the CommandLineSupport module
module Script
  # Support for command line arguments
  module CommandLineSupport
    # OptionsParser class
    class OptionsParser
      OPTION_METHODS = %i[head number_of_users dry_run teardown verbose tail].freeze
      attr_reader :parser, :options

      def initialize
        @parser = OptionParser.new
        @options = ::Script::UserCreatorScript.config.dup
        OPTION_METHODS.each { |method_name| method(method_name).call }
      end

      def head
        @parser.banner = "Usage: #{$PROGRAM_NAME} [options]"
        @parser.separator ''
        @parser.separator 'Options:'
      end

      def number_of_users
        @parser.on('--number_of_users=number', 'Number of users to create') do |v|
          @options[:number_of_users] = v.to_i
        end
      end

      def dry_run
        @parser.on('--dry-run=<yes/no>', 'Read-only mode is default') do |v|
          @options[:dry_run] = false if @options[:dry_run_pattern].match?(v)
        end
      end

      def teardown
        @parser.on('--teardown', 'Teardown users') { @options[:teardown] = true }
      end

      def verbose
        @parser.on('-v', '--verbose', 'Increase logging verbosity') do
          @options[:log_level] ||= 0
          @options[:log_level] -= 1
        end
      end

      def tail
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
# module Script

# Re-open the Script module to define the UserCreator class
module Script
  # The UserCreator class
  class UserCreator
    include ::Script::Logging
    attr_reader :options

    def initialize(options)
      @options = options
      log.level = @options[:log_level]
    end

    def destroy_users
      users = get_users
      if @options[:dry_run]
        log.info "[Dry-run] Would have destroyed #{users.length} users"
        return
      end

      log.info "Destroying #{users.length} users"
      users.destroy_all
    end

    def destroy_group
      group = get_group

      if @options[:dry_run]
        log.info "[Dry-run] Would have destroyed test group"
        return
      end

      return if group.nil?

      log.info "Destroying group: #{group&.name}"
      group&.destroy
    end

    def teardown
      destroy_users
      destroy_group
    end

    def create_group
      group_name = format(
        @options[:group_name_template],
        script_identifier: ::Script::UserCreatorScript::IDENTIFIER
      )

      if @options[:dry_run]
        log.info "[Dry-run] Would have invoked Group.create!(name: '#{group_name}')"
        return
      end

      log.info "Creating group with name: #{group_name}"
      Group.create!(name: group_name, path: group_name)
    end

    def get_group
      group_name = format(
        @options[:group_name_template],
        script_identifier: ::Script::UserCreatorScript::IDENTIFIER
      )
      log.info "Getting group by name: #{group_name}"
      group = Group.find_by(name: group_name)
      log.info "Not found: Group by name: #{group_name}" if group.nil?
      group
    end

    def get_users
      query = format(
        @options[:user_email_template],
        script_identifier: ::Script::UserCreatorScript::IDENTIFIER,
        iteration: '%'
      )
      log.info "Getting users matching query: email: #{query}"
      users = User.where('email ilike :query', query: query)
      log.info "Not found: Users by email: #{query}" if users.nil? || users.empty?
      users
    end

    def add_group_user(user)
      group = get_group || create_group

      if @options[:dry_run]
        log.info "[Dry-run] Would have invoked group.add_user(#{user&.email || 'user'})"
        return
      end

      return if group.nil? || user.nil?

      log.info "Adding user to group: #{group.name}"
      group.add_user(user, :developer)
      group.save!
    end

    def create_user(iteration_index)
      username = format(
        @options[:username_template],
        script_identifier: ::Script::UserCreatorScript::IDENTIFIER,
        iteration: iteration_index
      )
      email = format(
        @options[:user_email_template],
        script_identifier: ::Script::UserCreatorScript::IDENTIFIER,
        iteration: iteration_index
      )
      password = @options[:password]
      user_name = @options[:user_first_and_last_name]
      if @options[:dry_run]
        log.info "[Dry-run] Would have invoked User.create!(email: #{email}, " \
          "password: #{password}, name: #{user_name}, username: #{username})"
        return
      end

      log.info "Creating user with email: #{email}"
      user = User.create!(
        email: email,
        password: password,
        confirmed_at: DateTime.now,
        name: user_name,
        username: username
      )
      log.info "Created user: #{user.id}"
      user
    end

    def create_users(number_of_users = @options[:number_of_users])
      log.info "Creating #{number_of_users} users..."
      number_of_users.times do |i|
        user = create_user(i)
        add_group_user(user)
      end
    end
  end
  # class UserCreator
end
# module Script

# Re-open the Script module to add UserCreator module
module Script
  # UserCreatorScript module
  module UserCreatorScript
    include ::Script::Logging
    include ::Script::CommandLineSupport

    def main(args = parse(ARGV, ARGF))
      dry_run_notice if args[:dry_run]
      user_creator = ::Script::UserCreator.new(args)
      if args[:teardown]
        user_creator.teardown
        exit
      end

      user_creator.create_users
    rescue UserError => e
      log.error(e)
      abort
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
  # UserCreatorScript module
end
# module Script

# Anonymous object avoids namespace pollution
Object.new.extend(::Script::UserCreatorScript).main if $PROGRAM_NAME == __FILE__
