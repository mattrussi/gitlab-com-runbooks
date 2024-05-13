# frozen_string_literal: true

source 'https://rubygems.org'

gem 'colorize'
gem 'etc'
gem 'google-cloud-storage'
gem 'io-console'
gem 'json'
gem 'digest-crc'
gem 'terminal-table', '~> 3.0'
gem 'redis', '~> 5.2.0'
gem 'redis-clustering'
gem 'connection_pool', '~> 2.0'

group :development, :test do
  gem 'rake'
  gem 'pry', '~> 0.13'
  gem 'rspec'
  gem 'rspec-parameterized', ">= 1.0.0"
  gem 'rubocop'
  gem 'gitlab-styles', '~> 11.0', require: false
  gem 'bigdecimal'
  gem 'webmock'
  gem 'super_diff'
  gem 'byebug'
  gem 'socksify' # required to access Mimir via SOCKS5 locally
end

group :danger do
  gem 'gitlab-dangerfiles', '~> 4.0', require: false
end
