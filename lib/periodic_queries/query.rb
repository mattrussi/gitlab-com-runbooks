# frozen_string_literal: true

module PeriodicQueries
  class Query
    attr_reader :name, :type, :query, :params
    attr_writer :response

    def initialize(name, query_info)
      @name = name
      @type = query_info.delete('type')
      @params = query_info
    end

    def to_result
      {
        name => {
          success: success?,
          status_code: response&.status,
          message: response&.message,
          body: response&.parsed_body
        }
      }
    end

    def summary
      "#{response_status} #{name} (#{type}, params: #{params.keys.inspect})"
    end

    def success?
      !!response&.success?
    end

    private

    attr_reader :response

    def response_status
      return "➖" unless response

      response.success? ? "✔" : "❌"
    end
  end
end
