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


describe "TTCP Transmitting" do

  TEST_PORT = 5003

  specify "TTCP transmit over TCP to no server fails" do
    @ttcp = TTCP::TTCP.new :transmit => true, :tcp => true, :host => 'localhost', :port => TEST_PORT+1
    lambda { @ttcp.run }.should raise_error
  end

  specify "TTCP transmits over TCP, closing the connection when it's done" do

    thread = ThreadSocket.new do
      TCPServer.open TEST_PORT do |server|
        @socket = server.accept
        until @socket.eof?
          @socket.read 1000
        end
      end
    end

    sleep(0.2)

    thread.alive?.should be_true
    thread.socket.should be_nil

    @ttcp = TTCP::TTCP.new :transmit => true, :tcp => true, :host => 'localhost', :port => TEST_PORT
    lambda { @ttcp.run }.should_not raise_error
    @ttcp.duration.should_not be_nil
    @ttcp.duration.should > 0

    thread.join

    # connection has closed in server
    thread.socket.should be_nil

    # thread should have finished
    thread.alive?.should be_false
  end


  specify "TTCP transmit over UDP" do

    thread = ThreadSocket.new do
      @socket = UDPSocket.new
      @socket.bind('localhost', TEST_PORT)
      sentinel_count = 0
      until sentinel_count >= 2
        b = @socket.recv 2000
        sentinel_count += 1 if b.length <= 4
      end
    end

    sleep(0.2)

    thread.alive?.should be_true
    thread.socket.should_not be_nil

    @ttcp = TTCP::TTCP.new :transmit => true, :tcp => false, :udp => true, :host => 'localhost', :port => TEST_PORT
    lambda { @ttcp.run }.should_not raise_error
    @ttcp.duration.should_not be_nil
    @ttcp.duration.should > 0

    thread.join

    # connection has closed in server
    thread.socket.should be_nil

    # thread should have finished
    thread.alive?.should be_false
  end

  specify "TTCP receives over TCP from another TTCP sending to TCP" do

    thread = Thread.new do

      sleep 0.3

      ttcp2 = TTCP::TTCP.new :transmit => true, :tcp => true, :host => 'localhost', :port =>TEST_PORT
      ttcp2.run

    end

    sleep 0.1

    thread.alive?.should be_true

    @ttcp = TTCP::TTCP.new :receive=> true, :tcp => true, :host => 'localhost', :port =>TEST_PORT
    @ttcp.run

    @ttcp.duration.should_not be_nil
    @ttcp.duration.should > 0

    thread.join
    thread.alive?.should be_false
  end


  specify "TTCP receives over UDP from another TTCP sending to UDP" do

    thread = Thread.new do

      sleep 0.3

      ttcp2 = TTCP::TTCP.new :transmit => true, :tcp => false, :udp => true, :host => 'localhost', :port =>TEST_PORT
      ttcp2.run

    end

    sleep 0.1

    thread.alive?.should be_true

    @ttcp = TTCP::TTCP.new :receive=> true, :tcp => false, :udp => true, :host => 'localhost', :port =>TEST_PORT
    @ttcp.run

    @ttcp.duration.should_not be_nil
    @ttcp.duration.should > 0

    thread.join
    thread.alive?.should be_false
  end


end