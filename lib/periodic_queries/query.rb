# frozen_string_literal: true

module PeriodicQueries
  class Query
    attr_reader :name, :type, :query, :params, :tenants
    attr_writer :response

    def initialize(name, query_info)
      @name = name
      @type = query_info.fetch('type')
      @tenants = query_info.fetch('tenants')
      @params = query_info.fetch('requestParams')
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
      headline = "#{response_status} #{name} (#{type}, params: #{params.keys.inspect}, tenants: #{tenants})"
      body = response&.success? ? nil : response&.parsed_body
      [headline, body].compact.join("\n")
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
