# frozen_string_literal: true

require_relative './key_pattern'

module RedisTrace
  class Trace
    attr_accessor :timestamp, :command, :keys, :value, :value_type, :other_args, :successful, :response

    def initialize(timestamp, request)
      @timestamp = timestamp
      @request = request
      parse_request(request)
      @response = []
    end

    def request_size
      @request.reject(&:nil?).map(&:size).reduce(&:+) / 1024
    end

    def request_size
      @response.reject(&:nil?).map { |r| t.to_s.size }.reduce(&:+) / 1024
    end

    def to_s
      success = @successful ? '[SUCCESSFUL]' : '[ERROR]'
      "#{@timestamp} #{@request.join(" ")}\n#{success} #{@response.map(&:to_s).join(" ")}"
    end

    private

    def parse_request(request)
      @cmd = request[0].downcase

      @other_args = nil
      @value_type = nil
      @@value = nil

      case @cmd
      when "get"
        @keys = [request[1]]
      when "exists"
        @keys = request[1..]
      when "expire"
        @keys = [request[1]]
        @other_args = request[2..]
      when "pexpire"
        @keys = [request[1]]
        @other_args = request[2..]
      when "del"
        @keys = request[1..]
      when "mget"
        @keys = request[1..]
      when "set"
        @keys = [request[1]]
        @other_args = request[2..]
        @value = request[2]
      when "smembers"
        @keys = [request[1]]
      when "multi"
        @keys = []
      when "exec"
        @keys = []
      when "auth"
        @keys = []
      when "role"
        @keys = []
      when "info"
        @keys = []
        @other_args = [request[1]]
      when "memory"
        # MEMORY USAGE key [SAMPLES count]
        @keys = [request[2]]
        @other_args = [request[3..]]
      when "replconf"
        @keys = []
      when "ping"
        @keys = []
        @other_args = [request[1]]
      when "client"
        @keys = []
      when "sismember"
        @keys = [request[1]]
        @other_args = request[2..]
      when "incr"
        @keys = [request[1]]
      when "incrby"
        @keys = [request[1]]
        @value = request[2]
      when "incrbyfloat"
        @keys = [request[1]]
        @value = request[2]
        @value_type = "float"
      when "hincrby"
        @keys = [request[1]]
        @other_args = request[2..]
        @value = request[3]
      when "hdel"
        @keys = [request[1]]
        @other_args = request[2..]
      when "setex"
        @keys = [request[1]]
        @other_args = request[2..]
        @value = request[3]
      when "hmget"
        @keys = [request[1]]
        @other_args = request[2..]
      when "hmset"
        @keys = [request[1]]
        @other_args = request[2..]
        # Technically there could be an array of field names and @values ( HMSET key field @value [field @value ...] )
        # but GitLab doesn't use it AFAICT so i'm going to ignore that and hope.
        @value = request[3]
      when "unlink"
        @keys = request[1..]
      when "ttl"
        @keys = [request[1]]
      when "sadd"
        @keys = [request[1]]
        # Could be more than one; let's just grab the first, we only seem to use a single key in GitLab
        @other_args = request[2..]
        @value = request[2]
      when "hset"
        @keys = [request[1]]
        @other_args = request[2..]
        @value = request[3]
      when "publish"
        @keys = [request[1]]
        @other_args = request[2..]
        @value = request[3]
      when "eval"
        @keys = []
        @other_args = request[2..]
        # Could be more than one key though
        @value = request[3]
      when "strlen"
        @keys = [request[1]]
      when "pfadd"
        @keys = [request[1]]
        @other_args = request[2..]
      when "srem"
        @keys = [request[1]]
        @other_args = request[2..]
      when "hget"
        @keys = [request[1]]
        @other_args = request[2..]
      when "zadd"
        @keys = [request[1]]
        @other_args = request[2..]
        # well, "member" but that's sort of relevant
        @value = request[-1]
      when "zcard"
        @keys = [request[1]]
      when "decr"
        @keys = [request[1]]
      when "scard"
        @keys = [request[1]]
      when "subscribe"
        @keys = request[1..]
      when "unsubscribe"
        @keys = request[1..]
      when "zrangebyscore"
        @keys = [request[1]]
        @other_args = request[2..]
      when "zrevrange"
        @keys = [request[1]]
        @other_args = request[2..]
      when "zremrangebyrank"
        @keys = [request[1]]
        @other_args = request[2..]
      when "zremrangebyscore"
        @keys = [request[1]]
        @other_args = request[2..]
      when "blpop"
        @keys = request[1..-2]
        @value = request[-1]
      when "hgetall"
        @keys = [request[1]]
      when "lpush"
        @keys = [request[1]]
      else
        # Best guess
        @keys = [request[1]]
      end

      @value_type = @value.match(/^[0-9]+$/) ? "int" : "string" if @value && !@value_type
      @key_patterns = @keys.compact.map do |key|
        patternize(key).gsub(' ', '_')
      end
    end

    private

    def patternize(key)
      RedisTrace::KeyPattern.filter_key(key)
    end
  end
end
