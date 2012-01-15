require "rspec"
require 'spec_helper'

include TTCP

describe "TTCP Sockets" do

  after() do
    # ensure the ttcp instance is closed and destroyed
    if @ttcp.is_a? TTCP::TTCP
      @ttcp.close
    end
    @ttcp = nil
  end

  ##
  ## Setting up ttcp socket
  ##

  specify "ttcp in transmit tcp makes a tcp socket" do
    @ttcp = TTCP::TTCP.new :transmit => true, :tcp => true, :host => 'www.google.com', :port => 80
    TTCP::TTCP.publicize_methods do
      @ttcp.socket.should be_a(TCPSocket)
    end
  end

  specify "ttcp in transmit udp makes a udp socket" do
    @ttcp = TTCP::TTCP.new :transmit => true, :tcp => false, :udp => true, :host => 'localhost'
    TTCP::TTCP.publicize_methods do
      @ttcp.socket.should be_a(UDPSocket)
    end
  end

  specify "ttcp in receive tcp makes a tcp socket" do
    @ttcp = TTCP::TTCP.new :receive => true, :tcp => true, :host => 'localhost'
    TTCP::TTCP.publicize_methods do
      @ttcp.socket.should be_a(TCPSocket)
    end
  end

  specify "ttcp in receive udp makes a udp socket" do
    @ttcp = TTCP::TTCP.new :receive => true, :tcp => false, :udp => true, :host => 'localhost'
    TTCP::TTCP.publicize_methods do
      @ttcp.socket.should be_a(UDPSocket)
    end
  end

  specify "ttcp in udp has a minimum buffer length greater than 4" do
    @ttcp = TTCP::TTCP.new :transmit => true, :udp => true, :host => 'localhost', :length => 3
    @ttcp.options[:length].should > 4
  end

  specify "ttcp without options raises exception because neither transmit nor receive is specified" do
    lambda do
      @ttcp = TTCP::TTCP.new
      @ttcp.socket
    end.should raise_error
  end
end