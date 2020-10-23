#! /usr/bin/env ruby
# frozen_string_literal: true

# vi: set ft=ruby :

# -*- mode: ruby -*-

require 'json'
require 'logger'

begin
  require '/opt/gitlab/embedded/service/gitlab-rails/config/environment.rb'
rescue LoadError => e
  warn "WARNING: #{e.message}"
end

def usage
  puts "Usage: #{$PROGRAM_NAME} <project-full-paths-file>"
end

log = Logger.new(STDOUT)
log.level = Logger::INFO
log.formatter = proc do |level, t, _name, msg|
  format("%<timestamp>s %-5<level>s %<msg>s\n", timestamp: t.strftime('%Y-%m-%d %H:%M:%S'), level: level, msg: msg)
end

file_path = ARGV.shift
if file_path.nil? || file_path.empty?
  usage
  exit
end
file_dir_path = File.dirname(file_path)
file_name_without_extension = File.basename(file_path, '.' + File.basename(file_path).split('.').last)

log.info "Loading file: #{file_path}"

output_file_path = File.join(file_dir_path, file_name_without_extension + '.json')

projects = []
IO.readlines(file_path, chomp: true).each do |line|
  projects << { id: Project.find_by_full_path(line)[:id] }
end

log.info "Loaded #{projects.length} projects"

data = { projects: projects }

File.open(output_file_path, 'w') do |f|
  f.write(data.to_json)
end

log.info "Saved projects to: #{output_file_path}"
