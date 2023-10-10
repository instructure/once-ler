# frozen_string_literal: true

source 'http://rubygems.org'

plugin 'bundler-multilock', '1.2.0'
return unless Plugin.installed?('bundler-multilock')

Plugin.send(:load_plugin, 'bundler-multilock')

gemspec

%w[6.0 6.1 7.0 7.1].each do |ar|
  lockfile_name = "activerecord-#{ar}" unless ar == "7.1"
  lockfile lockfile_name do
    gem "globalid", ar == "6.0" ? "~> 1.1.0" : "~> 1.2"
    # rspec-rails depends on basically all of rails, so just use all of rails here
    gem 'rails', "~> #{ar}.0"
    gem 'rspec-rails', ar == "6.0" ? "~> 5.1.2" : "~> 6.0"
  end
end
