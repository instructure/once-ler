# frozen_string_literal: true

source 'http://rubygems.org'

plugin 'bundler-multilock', '1.1.2'
return unless Plugin.installed?('bundler-multilock')

Plugin.send(:load_plugin, 'bundler-multilock')

gemspec

group :test do
end

%w[6.0 6.1 7.0 7.1].each do |ar|
  lockfile "activerecord-#{ar}" do
    # rspec-rails depends on basically all of rails, so just use all of rails here
    gem 'rails', "~> #{ar}.0"
    if ar == "6.0"
      gem 'rspec-rails', "~> 5.1.2"
    end
  end
end
