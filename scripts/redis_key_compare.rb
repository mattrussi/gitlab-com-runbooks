# frozen_string_literal: true

require 'redis'
require 'yaml'
require 'redis-clustering'
require 'json'
require 'active_support'

def get_data(key, ktype, datastore)
  case ktype
  when 'string'
    datastore.get(key)
  when 'hash'
    datastore.hgetall(key)
  when 'set'
    datastore.smembers(key)
  else
    'Unsupported'
  end
end

# This file requires the `redis` gems.
#
# On a VM node, run the following to setup
# ```
# gem install redis -v '~> 4.8.0'
# ```
#
# Usage: ruby redis_key_compare.rb <KEY_1> <KEY_2>
#
# Pre-requisite: Create 2 files, source.yml and destination.yml with details of
# the source and destination redis instances.
# option 1: url: redis://<username>:<password>@<host>:<port>
# if cluster, define cluster(list of objects with host and port keys) + username + password

src = ::Redis.new(YAML.load_file('source.yml').transform_keys(&:to_sym))
dst = ::Redis::Cluster.new(YAML.load_file('destination.yml').transform_keys(&:to_sym).merge({ concurrency: { model: :none } }))

ARGV.each do |key|
  ktype = src.type(key)

  puts "#{key} is a #{ktype}"
  src_data_raw = get_data(key, ktype, src)
  dst_data_raw = get_data(key, ktype, dst)

  if src_data_raw.start_with?("v2:")
    src_data = JSON.parse(src_data_raw[3..])
    dst_data = JSON.parse(dst_data_raw[3..])
  elsif src_data_raw.start_with?("\x04")
    src_data = Marshal.load(src_data_raw).value
    dst_data = Marshal.load(dst_data_raw).value
  else
    puts "Unsupported value #{src_data_raw}"
    next
  end

  if src_data == dst_data
    puts "Same value for key #{key}"
    puts "--------------"
    next
  end

  if src_data["updated_at"] != dst_data["updated_at"] && src_data.except("updated_at") == dst_data.except("updated_at")
    puts "only updated_at mismatch for #{key} - src_data #{src_data['updated_at']} dst_data #{dst_data['updated_at']}"
    puts "--------------"
    next
  end

  puts "Different value for key #{key}"

  puts "Source data #{src_data}"
  puts "Destination data #{dst_data}"

  puts "--------------"
end
