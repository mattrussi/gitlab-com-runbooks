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
    else
      @result.data == expected
    end
  end

  description do
    "render jsonnet successfully"
  end

  failure_message do |actual|
    if @result.success?
      <<~EOF.strip
      Jsonnet rendered content does not match expectations:

      Jsonnet Content:
      ```
      #{actual}
      ```

      Jsonnet compiled data:
      ```
      #{@result.data}
      ```

      Expectations:
      #{::RSpec::Matchers.is_a_matcher?(expected) ? RSpec::Support::ObjectFormatter.format(expected) : expected}
      EOF
    else
      <<~EOF.strip
      Fail to render jsonnet content:
      ```
      #{actual}
      ```

      Error: #{@result.error_message}
      EOF
    end
  end
end

# Matchers for jsonnet rendering
RSpec::Matchers.define :reject_jsonnet do |expected|
  match do |actual|
    @result = JsonnetTestHelper.render(actual)
    next false if @result.success?

    raise 'reject_jsonnet matcher argument should be either nil or Regexp' if !expected.nil? && !expected.is_a?(Regexp)

    if expected.nil?
      true
    else
      @result.error_message.match?(expected)
    end
  end

  description do
    "reject jsonnet content with reason: #{expected.inspect}"
  end

  failure_message do |actual|
    if @result.success?
      'Jsonnet content renders successfully. Expecting an error!'
    else
      <<~EOF.strip
        Jsonnet error does not match

        Actual:
        ```
        #{@result.error_message}
        ```

        Expected:
        ```
        #{expected.inspect}
        ```
      EOF
    end
  end
end
