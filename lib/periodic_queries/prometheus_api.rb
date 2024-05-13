# frozen_string_literal: true

require 'net/http'
require_relative './prometheus_api/response'

module PeriodicQueries
  class PrometheusApi
    PATH_PER_QUERY = {
      'instant' => 'api/v1/query' # https://prometheus.io/docs/prometheus/latest/querying/api/#instant-queries
    }.freeze

    def initialize(url, tenant_id: nil, use_ssl: false, auth_token: nil)
      @base_url = url
      @use_ssl = use_ssl
      @tenant_id = tenant_id
      @auth_token = auth_token
    end

    def with_connection
      self.active_connection = Net::HTTP.new(uri.hostname, uri.port)
      active_connection.use_ssl = use_ssl
      active_connection.start
      yield(self)
    ensure
      active_connection.finish
    end

    def perform_query(query)
      path = PATH_PER_QUERY.fetch(query.type)
      query_uri = URI.join(base_url, path)
      query_uri.query = URI.encode_www_form(query.params)

      get = Net::HTTP::Get.new(query_uri, headers)
      # Net::HTTP#request does not raise exceptions, so we'll get an empty response
      # and continue to the next request
      # https://ruby-doc.org/stdlib-2.7.1/libdoc/net/http/rdoc/Net/HTTP.html#method-i-request
      Response.new(active_connection.request(get))
    end

    private

    attr_reader :base_url, :use_ssl, :tenant_id, :auth_token
    attr_accessor :active_connection

    def uri
      @uri ||= URI(base_url)
    end

    def headers
      @headers ||= {}.tap do |h|
        h['X-Scope-OrgID'] = tenant_id if tenant_id
        h['Authorization'] = auth_header if auth_header
      end
    end
  end
end
