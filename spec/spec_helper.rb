# frozen_string_literal: true

require 'rspec'
require 'kubernetes_rules'
require 'webmock/rspec'
require 'tmpdir'
require 'stringio'

def file_fixture(file)
  File.read(
    File.expand_path(File.join(File.dirname(__FILE__), "./fixtures/#{file}"))
  )
end
