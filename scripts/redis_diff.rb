# frozen_string_literal: true

require 'optparse'
require 'redis'
require 'yaml'

# This file requires the `redis` and `connection_pool` gems.
#
# On a VM node, run the following to setup
# ```
# gem install redis -v '~> 4.8.0'
# gem install connection_pool -v '~> 2.0'
# ```
#
# Usage: ruby redis_diff.rb --migrate --keys=1000
#
# Pre-requisite: Create 2 files, source.yml and destination.yml with details of
# the source and destination redis instances.
# option 1: url: redis://<username>:<password>@<host>:<port>
# if cluster, define cluster(list of objects with host and port keys) + username + password

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-m", "--migrate", "Copy mismatched key values (and their TTLs) from src to dst redis") do |v|
    options[:migrate] = v
  end

  opts.on("-k", "--keys=<number_of_keys>", "Number of keys to check") do |number_of_keys|
    options[:keys] = number_of_keys
  end

  opts.on("-c", "--cursor=<cursor>", "Cursor to start from") do |cursor|
    options[:cursor] = cursor
  end

  opts.on("-r", "--rate=<rate>", "Desired rate of keys being migrated per second") do |rate|
    options[:desired_rate] = rate
  end

  # TODO implement concurrency to speed up lookup
  opts.on("-c", "--concurrency=<nbr>", "Number of keys to check") do |nbr|
    options[:concurrency] = nbr
  end
end.parse!

# Ensure the ttl is also migrated for a key
def migrate_ttl(src, dst, key)
  ttl = src.ttl(key)
  return if ttl == -1 # key does not have associated ttl
  return dst.del(key) if ttl == -2 # expired in src db

  dst.expire(key, ttl)
end

# Strings
def compare_string(src, dst, key)
  src.get(key) == dst.get(key)
end

def migrate_string(src, dst, key)
  dst.set(key, src.get(key))
  migrate_ttl(src, dst, key)
end

# Hash
def compare_hash(src, dst, key)
  src.hgetall(key) == dst.hgetall(key)
end

def migrate_hash(src, dst, key)
  dst.hset(key, src.hgetall(key))
  migrate_ttl(src, dst, key)
end

# Set
def compare_set(src, dst, key)
  src_list = src.smembers(key)
  dst_list = dst.smembers(key)

  src_list & dst_list == src_list
end

def migrate_set(src, dst, key)
  dst.sadd(key, src.smembers(key))
  migrate_ttl(src, dst, key)
end

# TODO list, sorted sets

def compare_and_migrate(key, src, dst, migrate)
  ktype = src.type(key)
  identical = send("compare_#{ktype}", src, dst, key) # rubocop:disable GitlabSecurity/PublicSend
  unless identical
    puts "key #{key} differs"

    # alternatively we can run MIGRATE command but we need to know which port
    # and it only works when migrating from a lower Redis version to a higher Redis version
    if migrate # some argv
      puts "migrating #{key}..."
      send("migrate_#{ktype}", src, dst, key) # rubocop:disable GitlabSecurity/PublicSend
    end
  end

  !identical
end

desired_rate = (options[:desired_rate] || 500.0).to_f
it = options[:cursor] || "0"
checked = 0
diffcount = 0
migrated_count = 0

src_db = ::Redis.new(YAML.load_file('source.yml').transform_keys(&:to_sym))
dest_db = ::Redis.new(YAML.load_file('destination.yml').transform_keys(&:to_sym))

loop do
  it, keys = src_db.scan(it, match: "*")

  start = Time.now
  keys_to_recheck = []

  # first pass to compare and migrate keys if not identical
  keys.each_with_index do |key, idx|
    if compare_and_migrate(key, src_db, dest_db, options[:migrate])
      diffcount += 1
      keys_to_recheck << idx
    end
  end

  # perform a 2nd iteraation to recheck keys to confirm convergence
  # instead of immediately checking in the above loop
  if options[:migrate]
    keys.each_with_index do |key, idx|
      next unless keys_to_recheck.include?(idx)

      if !compare_and_migrate(key, src_db, dest_db, false)
        migrated_count += 1
      else
        # TODO write persistent mismatches into a tmp file?
        puts "Failed to migrate #{key}"
      end
    end
  end

  checked += keys.size
  duration = Time.now - start
  wait = (keys.size / desired_rate) - duration
  sleep(wait) if wait.positive?

  puts "Checked #{keys.size} keys from cursor #{it}"

  break if options[:keys] && checked > options[:keys].to_i
  break if it == "0"
end

puts "Checked #{checked}"
puts "#{diffcount} different keys"
puts "Migrated #{migrated_count} keys successfully"
