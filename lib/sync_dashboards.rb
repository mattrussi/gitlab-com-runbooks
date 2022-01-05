# frozen_string_literal: true
require 'json'
require 'fileutils'

require_relative './jsonnet_wrapper'

##
# Sync dashboards
module SyncDashboards
  def parse_jsonnet(jsonnet_file)
    raise "#{jsonnet_file} does not exist." unless File.exist?(jsonnet_file)

    JsonnetWrapper.new.parse(jsonnet_file)
  end

  def sync_dashboards(dashboards_dir, dashboards)
    dashboards = dashboards.to_h { |d| [trim_dashboard_file(d), d] }
    existing_dashboards = fetch_existing_dashboards(@dashboards_dir)

    FileUtils.mkdir_p(@dashboards_dir)

    delete_dashboards(existing_dashboards - dashboards.keys)
    add_dashboards(dashboards.keys - existing_dashboards, dashboards)
  end

  def fetch_existing_dashboards(dashboards_dir)
    existing_files = Dir["#{dashboards_dir}/*#{dashboard_extension}"]
    existing_files.map { |file| File.basename(file, dashboard_extension).strip }
  end

  def add_dashboards(names, name_translations)
    return if names.empty?

    output.puts "=== Adding #{names.length} dashboards"
    names.each do |name|
      output.puts "  - #{name}"
      file = dashboard_file(name)
      write_file(file, render_template(name_translations[name]))
    end
  end

  def delete_dashboards(names)
    return if names.empty?

    output.puts "=== Deleting #{names.length} dashboards"
    names.each do |name|
      file = dashboard_file(name)
      File.delete(file)
      output.puts "  - #{name}"
    end
  end

  def write_file(file, content)
    File.write(file, content)
    Kernel.system("make jsonnet-fmt JSONNET_FILES=#{file} > /dev/null", exception: true)
  end

  def format_template(content)
    # Remove whitespaces, empty lines and stuff to prevent trivial differences
    content.to_s.split("\n").map(&:strip).reject(&:empty?).join("\n")
  end

  def trim_dashboard_file(group)
    # Grafana's UID is generated based a dashboard's folder and file name.
    # Unfortunately, Grafana limits the max length to 40 characters. So, the
    # remaining length should be a bit shorter.
    group[0..(40 - self.class::DASHBOARDS_FOLDER.length - 2)]
  end
end
