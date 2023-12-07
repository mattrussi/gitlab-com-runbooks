#! /usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'net/http'

# Takes the input from `./scripts/compile_jsonnet.rb scripts/generate-service-dependencies.jsonnet > service-dependencies-raw.json`
THANOS_URL = ENV['THANOS_URL'] || 'http://localhost:10902'
THANOS_QUERY_API = "#{THANOS_URL}/api/v1/query"
SOURCE_JSON_FILE = 'service-dependencies-raw.json'

$service_dependencies_from_slis = {}
def fetch_type_dependencies(service, sli, query)
  uri = URI(THANOS_QUERY_API)
  params = {
    dedup: true,
    partial_response: true,
    query: query
  }
  uri.query = URI.encode_www_form(params)

  res = Net::HTTP.get_response(uri)

  raise "Thanos query API failed. Status: #{res.code} Message: #{res.message}" unless res.is_a?(Net::HTTPSuccess)

  parsed = JSON.parse(res.body)
  parsed['data']['result'].each do |r|
    emitting_service = r['metric']['type']
    next if emitting_service == service

    $service_dependencies_from_slis[emitting_service] ||= {}
    $service_dependencies_from_slis[emitting_service][sli] ||= Set.new
    $service_dependencies_from_slis[emitting_service][sli] << service
  end
end

file = File.read(SOURCE_JSON_FILE)
data = JSON.parse(file)
$all_services = data.keys

data.each do |service, value|
  value['slis'].each do |sli, sli_obj|
    request_rates_from_multiple_services = sli_obj['requestRate'].select { |rate| !rate['selector']['type'].is_a?(String) } # if type selector is a string, it's a single service
    request_rates_from_multiple_services.each do |rate|
      raw_query = rate['raw']
      aggregate_by_type = "count by (type) (#{raw_query})"
      puts "Querying Service: #{service} SLI: #{sli} Query: #{aggregate_by_type}"

      fetch_type_dependencies(service, sli, aggregate_by_type)
    end
  end
end

$service_dependencies_from_slis.each do |service, slis|
  slis.each do |sli, dependencies|
    $service_dependencies_from_slis[service][sli] = dependencies.to_a
  end
end

puts $service_dependencies_from_slis.to_json
puts 'Done'
