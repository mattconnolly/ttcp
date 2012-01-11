require_relative "ttcp/version"

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

    def self.default_options
      DEFAULT_OPTIONS
    end

    #
    # Create a TTCP test program instance. All configuration is done via the
    # options hash passed in here.
    #
    def initialize(options = {})
      @options = TTCP.default_options.merge options
    end

    #
    # Run the TTCP test program according to the options specified with the .new call
    #
    def run
      puts "running the ttcp program"

      if @options[:transmit]
        transmit
      elsif @options[:receive]
        receive
      else
        raise "TTCP must be configured to transmit or receive"
      end
    end

    private

    def transmit
      puts "Transmitting!"
    end

    def receive
      puts "Receiving!"
    end
  end
end
