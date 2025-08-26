# frozen_string_literal: true

source 'http://rubygems.org'

plugin 'bundler-multilock', '1.3.4'
return unless Plugin.installed?('bundler-multilock')

Plugin.send(:load_plugin, 'bundler-multilock')

gemspec

lockfile "activerecord-7.1" do
  gem "rails", "~> 7.1.0"
end

lockfile "activerecord-7.2" do
  gem 'rails', "~> 7.2.0"
end

lockfile do
  gem 'rails', "~> 8.0.0"
end
