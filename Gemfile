# frozen_string_literal: true

source "http://rubygems.org"

plugin "bundler-multilock", "1.4.0"
return unless Plugin.installed?("bundler-multilock")

Plugin.send(:load_plugin, "bundler-multilock")

gemspec

ruby31 = Gem::Requirement.new("~> 3.1.0").satisfied_by?(Gem::Version.new(RUBY_VERSION))

lockfile "activerecord-7.1" do
  gem "rails", "~> 7.1.0"

  gem "rspec-rails", "~> 7.1", require: false
end

lockfile "activerecord-7.2", active: ruby31 do
  gem "rails", "7.2.3"

  gem "rspec-rails", "~> 8.0", require: false
end

lockfile "activerecord-8.0" do
  gem "rails", "~> 8.0.0"

  gem "rspec-rails", "~> 8.0", require: false
end

lockfile active: !ruby31 do
  gem "rails", "~> 8.1.0"

  gem "rspec-rails", "~> 8.0", require: false
end

gem "database_cleaner", "~> 2.0", require: false
gem "database_cleaner-active_record", "~> 2.0", require: false
gem "debug", "~> 1.11", require: false
gem "rake", "~> 13.4", require: false
gem "rubocop-inst", "~> 1.2"
gem "rubocop-rake", "~> 0.7"
gem "rubocop-rspec", "~> 3.10"
gem "sqlite3", "~> 2.9", require: false
