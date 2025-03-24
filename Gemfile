# frozen_string_literal: true

source 'http://rubygems.org'

plugin 'bundler-multilock', '1.3.4'
return unless Plugin.installed?('bundler-multilock')

Plugin.send(:load_plugin, 'bundler-multilock')

gemspec

lockfile "activerecord-7.0" do
  gem "rails", "~> 7.0.0"
  gem "base64", "~> 0.1", require: RUBY_VERSION >= "3.4.0"
  gem "bigdecimal", "~> 3.1", require: RUBY_VERSION >= "3.4.0"
  gem "drb", "~> 2.1", require: RUBY_VERSION >= "3.4.0"
  gem "mutex_m", "~> 0.1", require: RUBY_VERSION >= "3.4.0"
end

lockfile "activerecord-7.1" do
  gem "rails", "~> 7.1.0"
end

lockfile do
  gem 'rails', "~> 7.2.0"
end
