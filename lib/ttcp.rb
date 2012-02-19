require_relative "ttcp/version"
require 'socket'

module TTCP

  DEFAULT_OPTIONS = {
      :transmit => false,
      :receive => false,
      :length => 8192,
      :udp => false,
      :tcp => true,
      :port => 5001,
      :verbose => false,
      :socket_debug => false,
      :format_rate => 'm',
      :num_buffers => 2048,
      :touch => false,
      :sink => true,
      :format => 'K',
  }

  def default_options
    DEFAULT_OPTIONS
  end


  class TTCP

    attr_reader :options
    attr_reader :bytes_received
    attr_accessor :stdout, :stderr

    def self.default_options
      DEFAULT_OPTIONS
    end

    #
    # Create a TTCP test program instance. All configuration is done via the
    # options hash passed in here.
    #
    def initialize(options = {})
      @options = TTCP.default_options.merge options

      if @options[:udp]
        # enforce buffer length to be more than udp sentinel size.
        @options[:length] = [@options[:length], 5].max
      end

      @bytes_received = 0

      # by default, use the stdout and stderr.
      @stdout = $stdout
      @stderr = $stderr

    end

    #
    # Run the TTCP test program according to the options specified with the .new call
    #
    def run
      begin
        # get the socket we will communicate on
        num_bytes = 0
        num_calls = 0

        #socket


        if @options[:transmit]
          message "buflen=%d, nbuf=%d, remote port=%d" % [@options[:length], @options[:num_buffers], @options[:port]]

          buf = source_buffer

          @start_time = Time.now
          @start_cpu_time = get_cpu_time

          socket.write "ttcp" if @options[:udp]
          @options[:num_buffers].times do
            socket.write buf
            num_bytes += buf.length
            num_calls += 1
          end
          socket.write "ttcp" if @options[:udp]

        elsif @options[:receive]
          message "buflen=%d, nbuf=%d, local port=%d" % [@options[:length], @options[:num_buffers], @options[:port]]

          receiving = true
          sentinel_count = 0

          if @options[:tcp]
            receiving_socket = socket.accept
            message("accept from #{receiving_socket.remote_address.ip_address}:#{receiving_socket.remote_address.ip_port}")
          else
            receiving_socket = socket
          end

          @start_time = Time.now
          @start_cpu_time = get_cpu_time

          while receiving

            buf = receiving_socket.recv @options[:length]
            num_bytes += buf.length unless buf.nil?
            num_calls += 1

            if buf.nil? || (@options[:tcp] && buf.length == 0)
              receiving = false
            else
              if @options[:udp]
                if buf.length <= 4
                  sentinel_count += 1
                  if sentinel_count >= 2
                    receiving = false
                  end
                else
                  sink buf
                  touch buf if @options[:touch]
                  @bytes_received += buf.length
                end
              end
            end
          end

          if @options[:tcp]
            receiving_socket.close unless receiving_socket.closed?
            receiving_socket = nil
          end

        end

      ensure
        @finish_time = Time.now
        @finish_cpu_time = get_cpu_time
        close
      end

      message("%d bytes in %.3f real seconds = %s/sec +++" % [num_bytes, duration, format_rate(num_bytes, duration)])

    end


    def duration
      @finish_time - @start_time if @finish_time
    end

    def cpu_duration
      @finish_cpu_time - @start_cpu_time if @finish_cpu_time
    end

    #
    # close any sockets
    #
    def close
      unless @socket.nil?
        begin
          @socket.shutdown Socket::SHUT_RDWR
        rescue
          # ignore any errors closing the socket
        ensure
          @socket = nil
        end
      end
    end


    #
    # set the stdout to point to nothing
    #
    def stdout_to_null
      @stdout = File.open("/dev/null", "w")
      @stderr = File.open("/dev/null", "w")
    end

    private

    # get the socket to be used for this ttcp run
    def socket

      if @socket.nil?

        state = "socket"

        begin
          if @options[:transmit]

            raise "Host not specified" unless @options[:host]

            # create a socket to transmit to
            if @options[:udp]
              @socket = UDPSocket.new
              message("socket")
              state = "connect"
              @socket.connect(@options[:host], @options[:port])
              message("connect")
            else
              @socket = TCPSocket.new(@options[:host], @options[:port])
              message("socket")
              message("connect")
            end

          elsif @options[:receive]

            # create a socket to receive from
            if @options[:udp]
              @socket = UDPSocket.new
              message("socket")
              state = "bind"
              @socket.bind(@options[:host], @options[:port])
              message("bind")
            else
              # create a TCPServer object
              args = []
              args << @options[:host] if @options[:host]
              args << @options[:port]
              @socket = TCPServer.new *args
              message("socket")
              state = "listen"
              @socket.listen 0
              message("listen")
            end

          else
            raise "TTCP must be configured to transmit or receive"
          end

        rescue Exception => e
          error(state, e)
        end
      end

      @socket
    end



    def source_buffer
      if @options[:sink]
        # source for sink is random data
        Random.new.bytes @options[:length]
      else
        # source for buffer is stdin
        $stdin.read @options[:length]
      end
    end


    #
    # send the received buffer to the appropriate place:stdout or the sink (null)
    def sink(buffer)
      if @options[:sink]
        #nothing, the sink
      else
        puts buffer
      end
    end


    #
    # read all the data in the buffer
    #
    def touch(buffer)
      sum = 0
      buffer.each_byte { |x| sum += x }
    end


    #
    # print output, like the `mes()` function in the original C ttcp program.
    #
    def message(str)
      mode = @options[:transmit] ? "t" : "r"
      @stdout.puts "ttcp-#{mode}: #{str}"
    end

    #
    # print output to stderr, like the `err()` function in the original C ttcp program.
    # instead of exiting, raise an exception and let the caller exit. If no exception is passed,
    # the error message is raised.
    def error(str, exception=nil)
      mode = @options[:transmit] ? "t" : "r"
      @stderr.puts "ttcp-#{mode}: #{str}"
      raise exception || str
    end

    # return combined user and system cpu time used by this process so far.
    def get_cpu_time
      tms = Process.times
      tms.utime + tms.stime
    end


    UNIT_FACTOR = {
        :k => [8 * 1024,    'Kbit'],
        :m => [8 * 1024**2, 'Mbit'],
        :g => [8 * 1024**3, 'Gbit'],
        :K => [1024,        'K'],
        :M => [1024**2,     'M'],
        :G => [1024**3,     'G']
    }

    # genrate a string representation of the date, according to the @options[:format] setting
    def format_rate(bytes, duration)
      d = [0.001, duration].max
      rate = bytes / d
      factor, unit = UNIT_FACTOR[@options[:format].to_sym]
      rate /= factor
      "%0.3f %s" % [rate, unit]
    end
  end
end
