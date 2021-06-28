# frozen_string_literal: true

require 'rspec'
require 'kubernetes_rules'
require 'webmock/rspec'
require 'tmpdir'
require 'stringio'
require 'pry'
require 'tempfile'
require 'rspec-parameterized'
require 'ruby_jard'

Dir[File.join(File.dirname(__FILE__), "/helpers/**.rb")].each do |helper_file|
  puts helper_file
  require File.expand_path(helper_file)
end

def file_fixture(file)
  File.read(
    File.expand_path(File.join(File.dirname(__FILE__), "./fixtures/#{file}"))
  )
end
