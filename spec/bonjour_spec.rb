require 'spec_helper.rb'

begin
  require 'dnssd'
  require 'timeout'

  def my_timeout(sec, *args, &block)
    begin
      did_timeout = false
      Timeout::timeout sec do
        yield *args
      end
    rescue Timeout::Error
      did_timeout = true
    end
    did_timeout
  end

  def my_timeout_thread(sec, *args, &block)
    Thread.new do
      my_timeout(sec, *args, &block)
    end
  end


  describe("Bonjour / DNSSD integration") do

    it "Advertises a receiving socket on bonjour / dnssd" do

      @ttcp = TTCP::TTCP.new :receive => true, :bonjour => true
      @ttcp.stdout_to_null

      background = Thread.new do
        @ttcp.run
      end

      query_responses = []
      my_timeout 5 do

        class Completed < Exception ; end

        begin
          services = {}
          DNSSD::browse!('_ttcp._tcp') do |reply|
            # browse for services
            services[reply.fullname] = reply
            # immediately add all the initially known ones to a list,
            next if reply.flags.more_coming?

            # and when there are no more known ones, resolve what we've found so far in background threads
            services.each_pair do |fullname, service|
              my_timeout_thread 4 do
                # (A) resolving the service into a name, target:port and text record
                # is running in a background thread, so that multiple DNSSD::Browse::Reply services can
                # be resolved in parallel (faster)
                DNSSD::Service.new.resolve service do |r|
                  if r.text_record["id"].to_i == @ttcp.unique_id
                    #puts "Found our TTCP!  #{r.name} at #{r.target}:#{r.port} on #{r.interface}"
                    query_responses << r
                  end

                  break unless r.flags.more_coming?
                end
              end
            end

            # clear the services list, this whole loop will start again if more services of the right type are
            # discovered.
            services.clear

            # it's possible that the main thread gets to this point before (A) above where the service has been
            # resolved. If that happens this block won't run again until there is a new service discovered. I
            # have seen some times the test takes the full 5 seconds time out, so this sleep is here to reduce the
            # chance of that happening.
            sleep 0.2

            # raising an exception is the only way to exit the synchronous browse yield loop from in the same thread
            raise Completed unless query_responses.empty?
          end
        rescue Completed
          # not an error
        end
      end

      # stop the ttcp program running in the background
      if background
        background.kill
        background.join
      end

      query_responses.should_not be_empty

    end
  end

rescue LoadError
  puts "Skipping Bonjour / DNSSD tests because can't find the 'dnssd' gem."
  puts "Run 'gem install dnssd' and try again."
end
