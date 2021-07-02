# frozen_string_literal: true

require 'rspec'
require 'kubernetes_rules'
require 'webmock/rspec'
require 'tmpdir'
require 'stringio'
require 'pry'
require 'tempfile'
require 'rspec-parameterized'
require 'super_diff/rspec'

SuperDiff.configure do |config|
  config.actual_color = :green
  config.expected_color = :red
  config.border_color = :yellow
  config.header_color = :yellow
  config.diff_elision_enabled = true
end

RSpec.configuration.color = true

Dir[File.join(File.dirname(__FILE__), "/helpers/**.rb")].each do |helper_file|
  require File.expand_path(helper_file)
end

def file_fixture(file)
  File.read(
    File.expand_path(File.join(File.dirname(__FILE__), "./fixtures/#{file}"))
  )
end
