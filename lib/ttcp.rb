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
  }

  def default_options
    DEFAULT_OPTIONS
  end


  class TTCP

    attr_reader :options
    attr_reader :bytes_received

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
    end

    #
    # Run the TTCP test program according to the options specified with the .new call
    #
    def run
      begin
        # get the socket we will communicate on
        socket

        @start_time = Time.now

        if @options[:transmit]
          puts "ttcp-t buflen=%d, nbuf=%d, remote port=%d" % [@options[:length], @options[:num_buffers], @options[:port]]

          b = source_buffer

          socket.write "ttcp" if @options[:udp]
          @options[:num_buffers].times do
            socket.write b
          end
          socket.write "ttcp" if @options[:udp]

        elsif @options[:receive]
          puts "ttcp-r buflen=%d, nbuf=%d, local port=%d" % [@options[:length], @options[:num_buffers], @options[:port]]

          receiving = true
          sentinel_count = 0

          while receiving
            buf = socket.recv @options[:length]
            if buf.nil?
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

        end

      ensure
        @finish_time = Time.now
        close
      end

    end


    def duration
      @finish_time - @start_time if @finish_time
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

    private

    # get the socket to be used for this ttcp run
    def socket

      if @socket.nil?
        if @options[:transmit]

          raise "Host not specified" unless @options[:host]

          # create a socket to transmit to
          if @options[:udp]
            @socket = UDPSocket.new
            @socket.connect(@options[:host], @options[:port])
          else
            @socket = TCPSocket.new(@options[:host], @options[:port])
          end

        elsif @options[:receive]

          # create a socket to receive from
          if @options[:udp]
            @socket = UDPSocket.new
            @socket.bind(@options[:host], @options[:port])
          else
            # create a TCPServer object
            args = []
            args << @options[:host] if @options[:host]
            args << @options[:port]
            @socket = TCPServer.new *args
            @socket.listen 0
          end

        else
          raise "TTCP must be configured to transmit or receive"
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
  end
end
