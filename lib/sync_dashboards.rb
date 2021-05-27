# frozen_string_literal: true
require 'json'
require 'fileutils'
require 'open3'
require 'English'

##
# Sync dashboards
module SyncDashboards
  def parse_jsonnet(jsonnet_file)
    raise "#{jsonnet_file} does not exist." unless File.exist?(jsonnet_file)

    group_info_json = IO.popen("jsonnet \"#{jsonnet_file}\"", &:read)
    raise "Fail to compile #{jsonnet_file}" unless $CHILD_STATUS.success?

    JSON.parse(group_info_json)
  end

  def sync_dashboards(dashboards_dir, dashboards)
    existing_dashboards = fetch_existing_dashboards(@dashboards_dir)

    FileUtils.mkdir_p(@dashboards_dir)

    delete_dashboards(existing_dashboards - dashboards)
    add_dashboards(dashboards - existing_dashboards)
  end

  def fetch_existing_dashboards(dashboards_dir)
    existing_files = Dir["#{dashboards_dir}/*#{dashboard_extension}"]
    existing_files.map { |file| File.basename(file, dashboard_extension).strip }
  end

  def add_dashboards(names)
    return if names.empty?

    output.puts "=== Adding #{names.length} dashboards"
    names.each do |name|
      output.puts "  - #{name}"
      file = dashboard_file(name)
      write_file(file, render_template(name))
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
end
