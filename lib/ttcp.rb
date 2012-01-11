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

    def initialize(options = {})
      @options = options
    end
  end
end
