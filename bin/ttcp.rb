#!/usr/bin/env ruby
#
# ttcp
# ©2012 Matt Connolly
#
# This is a ruby implementation of the TTCP network test program.
#



require 'optparse'
require_relative '../lib/ttcp'

include TTCP

=begin
Usage: ttcp -t [-options] host [ < in ]\n\
ttcp -r [-options > out]\n\
Common options:\n\
-l ##	length of bufs read from or written to network (default 8192)\n\
-u	use UDP instead of TCP\n\
-p ##	port number to send to or listen at (default 5001)\n\
-s	-t: source a pattern to network\n\
-r: sink (discard) all data from network\n\
-A	align the start of buffers to this modulus (default 16384)\n\
-O	start buffers at this offset from the modulus (default 0)\n\
-v	verbose: print more statistics\n\
-d	set SO_DEBUG socket option\n\
-b ##	set socket buffer size (if supported)\n\
-f X	format for rate: k,K = kilo{bit,byte}; m,M = mega; g,G = giga\n\
Options specific to -t:\n\
-n##	number of source bufs written to network (default 2048)\n\
-D	don't buffer TCP writes (sets TCP_NODELAY socket option)\n\
Options specific to -r:\n\
-B	for -s, only output full blocks as specified by -l (for TAR)\n\
-T	\"touch\": access each byte as it's read\n\
=end

#
# defaults:
#

options = default_options

optparse = OptionParser.new do |opts|
  opts.banner = <<END
Usage: ttcp.rb -t [options] host [ < in ]
       ttcp.rb -r [options > out]

Common options:
-l ##	length of bufs read from or written to network (default 8192)
-u	use UDP instead of TCP
-p ##	port number to send to or listen at (default 5001)
-s	-t: source a pattern to network
-r: sink (discard) all data from network
###-A	align the start of buffers to this modulus (default 16384)
###-O	start buffers at this offset from the modulus (default 0)
-v	verbose: print more statistics
###-d	set SO_DEBUG socket option
###-b ##	set socket buffer size (if supported)
-f X	format for rate: k,K = kilo{bit,byte}; m,M = mega; g,G = giga
Options specific to -t:
-n##	number of source bufs written to network (default 2048)
###-D	don't buffer TCP writes (sets TCP_NODELAY socket option)
Options specific to -r:
###-B	for -s, only output full blocks as specified by -l (for TAR)
-T	\"touch\": access each byte as it's read
END

  opts.on('-l', '--length NUM', "Length of bufs read from or written to network (default #{options[:length]})") do |length|
    options[:length] = length.to_i if length.to_i > 0
  end

  opts.on('-u', '--udp', 'Use UDP instead of TCP') do
    options[:udp] = true
    options[:tcp] = false
  end

  opts.on('--tcp', 'Use TCP instead of UDP') do
    options[:udp] = false
    options[:tcp] = true
  end

  opts.on('-t', '--transmit', "Transmit data to another TTCP program") do
    options[:transmit] = true
    options[:receive] = false
  end

  opts.on('-r', '--receive',  "Receive data from another TTCP program") do
    options[:receive] = true
    options[:transmit] = false
  end

  opts.on('-s', '--sink',
          "When transmitting, source pattern to network.",
          "When receiving, discard all incoming data") do
    options[:sink] = !options[:sink]
  end

  opts.on('-p', '--port PORT', "Receive on port PORT / Transmit to remote port PORT") do |port|
    options[:port] = port.to_i if port.to_i > 0
  end

  opts.on('-v', '--verbose', "Verbose output") { options[:verbose] = true }
  opts.on('-T', '--touch', "Touch (access) all incoming data") { options[:touch] = true }

  opts.on('-n', '--numbufs NUM', "Set number of buffers to send / receive (default = #{options[:num_buffers]})") do |num|
    options[:num_buffers] = num.to_i if num.to_i > 0
  end
end


optparse.parse!


unless options[:transmit] || options[:receive]

  puts optparse.help
  exit(1)

end

puts options.inspect