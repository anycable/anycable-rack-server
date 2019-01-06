source 'https://rubygems.org'

gemspec

gem "pry-byebug"

gem "rails", "~> 5.2"

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
end
