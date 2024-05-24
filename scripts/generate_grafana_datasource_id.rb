# frozen_string_literal: true

require 'yaml'

unless ARGV.length == 2
  puts "Usage: ruby generate_grafana_datasource_id.rb <file.yml> <grafana_datasource_id>"
  exit
end

name = ARGV[0]
datasource_id = ARGV[1]
output = ""

File.open(name, "rt") do |file|
  file.each_line do |line|
    output += line
    object = line.strip

    next unless object == "annotations:"

    indent = line.match(/^\s*/)[0].length + 2
    datasource_line = " " * indent
    datasource_line += "grafana_datasource_id: #{datasource_id}\n"
    output += datasource_line
  end
end

File.open(name, "w") do |file|
  file.puts output
end
