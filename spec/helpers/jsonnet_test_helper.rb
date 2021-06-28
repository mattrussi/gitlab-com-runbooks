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

# Matchers for jsonnet rendering
RSpec::Matchers.define :render_jsonnet do |expected|
  match do |actual|
    raise 'render_jsonnet matcher supports either argument or block' if !block_arg.nil? && !expected.nil?

    @result = JsonnetTestHelper.render(actual)
    next false unless @result.success?

    unless block_arg.nil?
      next block_arg.call(@result.data)
    end

    if ::RSpec::Matchers.is_a_matcher?(expected)
      expected.matches?(@result.data)
    elsif expected.is_a?(Hash)
      @result.data == expected
    else
      raise "render_jsonnet matcher does not support #{expected.class} expected argument"
    end
  end

  failure_message do |actual|
    if @result.success?
      <<~EOF
      Jsonnet rendered content does not match expectations:

      Jsonnet Content:
      ```
      #{actual}
      ```

      Expectations:
      #{::RSpec::Matchers.is_a_matcher?(expected) ? RSpec::Support::ObjectFormatter.format(expected) : expected}
      EOF
    else
      "Fail to render jsonnet content: `#{actual}`"
    end
  end
end

# Matchers for jsonnet rendering
RSpec::Matchers.define :reject_jsonnet do |expected|
  match do |actual|
    raise 'reject_jsonnet matcher supports either argument or block' if !block_arg.nil? && !expected.nil?

    @result = JsonnetTestHelper.render(actual)
    next false if @result.success?

    if expected.nil?
      true
    elsif ::RSpec::Matchers.is_a_matcher?(expected)
      expected.matches?(@result.error_message)
    elsif expected.is_a?(Regexp)
      @result.error_message =~ expected
    elsif expected.is_a?(String)
      @result.error_message == expected
    else
      raise "reject_jsonnet matcher does not support #{expected.class} expected argument"
    end
  end

  failure_message do |actual|
    if @result.success?
      'Jsonnet content renders successfully. Expecting an error!'
    else
      "Jsonnet error does not match. Actual: `#{actual}`. Expected: #{expected}"
    end
  end
end
