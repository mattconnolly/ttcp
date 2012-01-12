require "rspec"
require 'spec_helper'

include TTCP

describe "TTCP" do

  specify "ttcp in transmit tcp makes a tcp socket" do
    ttcp = TTCP::TTCP.new :transmit => true, :tcp => true, :host => 'www.google.com', :port => 80
    TTCP::TTCP.publicize_methods do
      ttcp.socket.class.should == TCPSocket
    end
  end

  specify "ttcp in transmit udp makes a udp socket" do
    ttcp = TTCP::TTCP.new :transmit => true, :udp => true, :host => 'localhost'
    TTCP::TTCP.publicize_methods do
      ttcp.socket.class.should == UDPSocket
    end
  end

  specify "ttcp in receive tcp makes a tcp socket" do
    ttcp = TTCP::TTCP.new :receive => true, :udp => true, :host => 'localhost'
    TTCP::TTCP.publicize_methods do
      ttcp.socket.class.should == UDPSocket
    end
  end

  specify "ttcp in receive udp makes a udp socket" do
    ttcp = TTCP::TTCP.new :receive => true, :udp => true, :host => 'localhost'
    TTCP::TTCP.publicize_methods do
      ttcp.socket.class.should == UDPSocket
    end
  end

  specify "ttcp in udp has a minimum buffer length greater than 4" do
    ttcp = TTCP::TTCP.new :transmit => true, :udp => true, :host => 'localhost', :length => 3
    ttcp.options[:length].should > 4
  end

end