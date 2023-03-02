# frozen_string_literal: true

source 'https://rubygems.org'

ruby file: '.ruby-version'

gem 'rails', '~> 8.1.0'

gem 'bootsnap', require: false
gem 'csv', '~> 3.3'
gem 'dartsass-sprockets', '~> 3.2'
gem 'dotenv-rails', '~> 3.1'
gem 'importmap-rails', '~> 2.1'
gem 'kaminari', '~> 1.2'
gem 'pg', '~> 1.5'
gem 'puma', '~> 8.0'
gem 'simple_form', '~> 5.3'
gem 'sprockets-rails', '~> 3.5'
gem 'stimulus-rails', '~> 1.3'
gem 'turbo-rails', '~> 2.0'

# Windows does not ship zoneinfo files.
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development, :test do
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'faker', '~> 3.5'
  gem 'rspec-rails', '~> 8.0'
end

group :development do
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false
  gem 'web-console'
end

group :test do
  gem 'rails-controller-testing', '~> 1.0'
  gem 'shoulda-matchers', '~> 6.4'
end
