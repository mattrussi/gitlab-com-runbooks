# frozen_string_literal: true
require 'net/http'
require_relative './prometheus_api/response'

module PeriodicQueries
  class PrometheusApi
    PATH_PER_QUERY = {
      'instant' => '/api/v1/query' # https://prometheus.io/docs/prometheus/latest/querying/api/#instant-queries
    }.freeze

    def initialize(url)
      @base_url = url
    end

    def with_connection
      self.active_connection = Net::HTTP.new(uri.hostname, uri.port)
      active_connection.start
      yield(self)
    ensure
      active_connection.finish
    end

    def perform_query(query)
      path = PATH_PER_QUERY.fetch(query.type)
      query_uri = URI.join(base_url, path)
      query_uri.query = URI.encode_www_form(query.params)

      get = Net::HTTP::Get.new(query_uri)
      # Net::HTTP#request does not raise exceptions, so we'll get an empty response
      # and continue to the next request
      # https://ruby-doc.org/stdlib-2.7.1/libdoc/net/http/rdoc/Net/HTTP.html#method-i-request
      Response.new(active_connection.request(get))
    end

    private

    attr_reader :base_url
    attr_accessor :active_connection

    def uri
      @uri ||= URI(base_url)
    end
  end
end
