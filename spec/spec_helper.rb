require 'ttcp'
require 'ttcp/version'
require 'socket'


class Class
  def publicize_methods
    saved_private_instance_methods = self.private_instance_methods
    self.class_eval { public *saved_private_instance_methods }
    yield
    self.class_eval { private *saved_private_instance_methods }
  end
end


class ThreadSocket

  attr_reader :socket

  def initialize(&block)
    @thread = Thread.new do
      begin
        @socket = nil
        instance_eval(&block)
      rescue Exception => x
        puts "Exception in ThreadSocket: #{x}"
      ensure
        begin
          @socket.shutdown(Socket::SHUT_RDWR) if @socket && @socket.is_a?(BasicSocket)
        rescue
          # ignore errors shutting down the socket
        end
        @socket = nil
      end
    end
  end

  # forward not implemented method calls to the thread
  def method_missing(method_name, *args, &block)
    if @thread && @thread.respond_to?(method_name)
      @thread.__send__(method_name, *args, &block)
    else
      super(method_name, *args, &block)
    end
  end


end
