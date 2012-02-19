# ttcp (Test TCP) - Benchmarking Tool and Simple Network Traffic Generator

This is a ruby version of the original C ttcp program.

This tool aims to be a drop in replacement for the original C version, with interoperable networking and command line options. ie: you can have the C and ruby versions talk to each other.

http://www.pcausa.com/Utilities/pcattcp.htm

## Installation

Run `$ gem install ttcp`.

## Usage

Similar to the original TTCP program, run a receiver on one machine and a transmitter on another, in that order:
```machine1$ ttcp -r [-p <port>]
```

And:
```machine2$ ttcp -t <machine1_ip_address> [-p port]
```

For more command line options run:
```machine1$ ttcp --help
```

## Dependencies

Runtime dependencies:

* only ruby std libraries

Development dependencies:

* bundler
* rake
* rpsec
* ci_reporter (for use with jenkins)

Optionally:

* guard
* guard-rspec

## Compatibility

* MRI ruby 1.9.2+, or
* JRuby in 1.9 compat mode

## Contributing

1. Fork
2. Install dependencies by running `$ bundle install`
3. Write tests and code
4. Make sure the tests pass by running `$ rake test`
5. Push and send a pull request on GitHub

## Known issues

* Tests don't seem to run in JRuby 1.6.5, but the TTCP program works itself.

## Credits

Special thanks to the Mike Muuss and Terry Slattery and other contributors of the original TTCP program.

## Copyright

Copyright © 2012 Matt Connolly. Released under the MIT license. See LICENSE.
