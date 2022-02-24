# frozen_string_literal: true
require 'time'
require_relative '../lib/redis_trace/key_pattern'

raise 'no input file provided' if ARGV.empty?

ARGV.each do |idx_filename|
  filename = idx_filename.gsub(/\.findx$/, "")

  warn filename

  index_keys = []
  index_vals = []

  File.readlines(idx_filename).each do |line|
    offset, timestamp, _length = line.strip.split("|")

    index_keys << offset.to_i
    index_vals << timestamp.to_f
  end

  File.open(filename, 'r:ASCII-8BIT') do |f|
    until f.eof?
      begin
        offset = f.tell
        line = f.readline.strip

        next unless line.match(/^\*([0-9]+)$/)

        args = []

        argc = Regexp.last_match(1).to_i
        argc.times do
          line = f.readline.strip
          raise unless line.match(/^\$([0-9]+)$/)

          len = Regexp.last_match(1).to_i
          args << f.read(len)
          f.read(2) # \r\n
        end

        i = index_keys.bsearch_index { |v| v >= offset }
        if i.nil?
          i = index_keys.size - 1
        elsif i.positive? && index_keys[i] != offset
          # bsearch rounds up, we want to round down
          i -= 1
        end

        cmd = args[0].downcase
        ts = Time.at(index_vals[i]).to_datetime.new_offset(0)
        # kbytes = args.reject(&:nil?).map(&:size).reduce(&:+) / 1024

        raise unless File.basename(filename).match(/^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\.([0-9]+)-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\.([0-9]+)$/)

        src_host = Regexp.last_match(1).split('.').map(&:to_i).join('.')
        # src_port = Regexp.last_match(2).to_i
        # dst_host = Regexp.last_match(3).split('.').map(&:to_i).join('.')
        # dst_port = Regexp.last_match(4).to_i

        case cmd
        when "blpop"
          keys = [args[1..-2]]
        when "get"
          keys = [args[1]]
        when "exists"
          keys = args[1..]
        when "expire"
          keys = [args[1]]
        when "del"
          keys = args[1..]
        when "mget"
          keys = args[1..]
        when "set"
          keys = [args[1]]
        when "smembers"
          keys = [args[1]]
        when "multi"
          keys = []
        when "exec"
          keys = []
        when "auth"
          keys = []
        when "role"
          keys = []
        when "info"
          keys = []
        when "memory"
          keys = []
        when "replconf"
          keys = []
        when "ping"
          keys = []
        when "client"
          keys = []
        when "sismember"
          keys = [args[1]]
        when "incr"
          keys = [args[1]]
        when "incrby"
          keys = [args[1]]
        when "incrbyfloat"
          keys = [args[1]]
        when "hincrby"
          keys = [args[1]]
        when "hscan"
          keys = [args[1]]
        when "hdel"
          keys = [args[1]]
        when "setex"
          keys = [args[1]]
        when "hmget"
          keys = [args[1]]
        when "hmset"
          keys = [args[1]]
        when "unlink"
          keys = args[1..]
        when "ttl"
          keys = [args[1]]
        when "sadd"
          keys = [args[1]]
        when "hset"
          keys = [args[1]]
        when "publish"
          keys = [args[1]]
        when "eval"
          keys = []
        when "strlen"
          keys = [args[1]]
        when "pfadd"
          keys = [args[1]]
        when "pexpire"
          keys = [args[1]]
        when "srem"
          keys = [args[1]]
        when "hget"
          keys = [args[1]]
        when "zadd"
          keys = [args[1]]
        when "zcard"
          keys = [args[1]]
        when "decr"
          keys = [args[1]]
        when "scard"
          keys = [args[1]]
        when "subscribe"
          keys = args[1..]
        when "unsubscribe"
          keys = args[1..]
        when "zrangebyscore"
          keys = [args[1]]
        when "zrevrange"
          keys = [args[1]]
        when "zremrangebyrank"
          keys = [args[1]]
        when "zremrangebyscore"
          keys = [args[1]]
        else
          raise "unknown command #{cmd}"
        end

        keys.each do |key|
          puts "#{ts.iso8601(9)} #{ts.to_time.to_i % 60} #{cmd} #{src_host} #{RedisTrace::KeyPattern.filter_key(key).gsub(' ', '_').inspect} #{key.gsub(' ', '_').inspect}"
        end
      rescue EOFError
      end
    end
  end
end
