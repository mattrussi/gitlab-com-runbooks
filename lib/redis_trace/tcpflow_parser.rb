# frozen_string_literal: true

require_relative './trace'

module RedisTrace
  class TcpflowParser
    def initialize(idx_filename)
      @idx_filename = idx_filename
    end

    def call
      parse_idx_file

      request_filename = @idx_filename.gsub(/\.findx$/, "")
      raise "Invalid file name #{request_filename}" unless File.basename(request_filename).match(/^([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\.([0-9]+)-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\.([0-9]+)$/)

      request_file = File.open(request_filename, 'r:ASCII-8BIT')

      response_filename = File.join(
        File.dirname(request_filename),
        File.basename(request_filename).split("-").reverse.join("-")
      )
      response_file = File.open(response_filename, 'r:ASCII-8BIT')

      until request_file.eof?
        trace = parse_next_request(request_file)
        next if trace.nil?

        successful, response = parse_next_response(response_file)
        trace.successful = successful
        trace.response = response
        yield trace if block_given?
      end
    ensure
      request_file&.close
      response_file&.close
    end

    private

    def parse_idx_file
      @index_keys = []
      @index_vals = []

      File.readlines(@idx_filename).each do |line|
        offset, timestamp, _length = line.strip.split("|")

        @index_keys << offset.to_i
        @index_vals << timestamp.to_f
      end
    end

    def request_timestamp(offset)
      i = @index_keys.bsearch_index { |v| v >= offset }
      if i.nil?
        i = @index_keys.size - 1
      elsif i.positive? && @index_keys[i] != offset
        # bsearch rounds up, we want to round down
        i -= 1
      end

      Time.at(@index_vals[i]).to_datetime.new_offset(0)
    end

    def parse_next_request(request_file)
      offset = request_file.tell
      line = request_file.readline.strip

      return unless line.match(/^\*([0-9]+)$/)

      # Parse request
      request = []
      argc = Regexp.last_match(1).to_i
      argc.times do
        line = request_file.readline.strip
        raise "Invalid line: #{line}" unless line.match(/^\$([0-9]+)$/)

        len = Regexp.last_match(1).to_i
        request << request_file.read(len)
        request_file.read(2) # \r\n
      end

      # Search index file for timestamps
      timestamp = request_timestamp(offset)

      Trace.new(timestamp, request)
    rescue EOFError
      nil
    end

    def parse_next_response(response_file)
      # https://redis.io/topics/protocol
      line = nil
      loop do
        line = response_file.readline.strip
        break if line.match(/^[*:\-+$].*/)
      end

      if line.match(/^\*([0-9]+)$/)
        argc = Regexp.last_match(1).to_i
        response = argc.times.map do
          line = response_file.readline.strip
          parse_response_line(line, response_file)
        end
        return [true, response]
      end

      return [false, [Regexp.last_match(1)]] if line.match(/^-(.*)$/)

      [true, [parse_response_line(line, response_file)]]
    rescue EOFError
      [true, []]
    end

    def parse_response_line(line, response_file)
      if ['+OK', '+QUEUED'].include?(line)
        line
      elsif line == '$-1'
        nil
      elsif line.match(/^:([0-9]+)$/)
        Regexp.last_match(1).to_i
      elsif line.match(/^\$([0-9]+)$/)
        len = Regexp.last_match(1).to_i

        str = response_file.read(len)
        response_file.read(2) # \r\n
        str
      else
        raise "Unknown signal: #{line}"
      end
    end
  end
end
