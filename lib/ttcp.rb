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
  }

  def default_options
    DEFAULT_OPTIONS
  end


  class TTCP

    attr_reader :options

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

    end

    #
    # Run the TTCP test program according to the options specified with the .new call
    #
    def run
      puts "running the ttcp program"

      # get the socket we will communicate on
      socket

      if @options[:transmit]
        puts "ttcp-t buflen=%d, nbuf=%d, port=%d" % [@options[:length], @options[:num_buffers], @options[:port]]
      else
        puts "ttcp-r"
      end


    end

    #
    # close any sockets
    #
    def close
      unless @socket.nil?
        begin
          @socket.shutdown
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

  end
end
