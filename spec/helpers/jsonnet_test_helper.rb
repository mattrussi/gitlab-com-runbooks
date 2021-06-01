# frozen_string_literal: true

require_relative '../../lib/jsonnet_wrapper'

class JsonnetTestHelper
  def self.render(content)
    new.tap { |helper| helper.render(content) }
  end

  def render(content)
    file = Tempfile.new('file.jsonnet')
    file.write(content)
    file.close

    @data = JsonnetWrapper.new.parse(file.path)
  rescue StandardError => e
    @error = e
  ensure
    @rendered = true
    file.unlink
  end

  def success?
    raise 'Content has not been render'  unless @rendered

    @error.nil?
  end

  def error_message
    @error.message
  end

  def data
    raise 'Content has not been render'  unless @rendered

    @data
  end

  private

  def initialize
    @rendered = false
    @error = nil
  end
end
