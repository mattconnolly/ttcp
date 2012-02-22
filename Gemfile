source "http://rubygems.org"

# Specify your gem's dependencies in ttcp-rb.gemspec
gemspec

# optional dependencies (not included in gemspec):
group :development, :test do
  gem 'guard'
  gem 'guard-rspec'
end

# use bundle --without bonjour to not have dnssd loaded.
group :bonjour do
  gem 'dnssd'
end

