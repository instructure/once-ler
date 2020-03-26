appraise "rspec-3.6-ar-5.0" do
  gem "activerecord", "~> 5.0.0"
  gem "database_cleaner", "~> 1.7.0"
  gem "rspec", "~> 3.6.0"
  gem "sqlite3", "~> 1.3.13"
end

appraise "rspec-3.6-ar-5.2" do
  gem "activerecord", "~> 5.2.0"
  gem "database_cleaner", "~> 1.7.0"
  gem "rspec", "~> 3.6.0"
  gem "sqlite3", "~> 1.3.13"
end

# Note: Rails 5.x requires sqlite3 ~> 1.3
%w[5.0 5.2].each do |ar|
  appraise "rspec-3.9-ar-#{ar}-dc-1.7" do
    gem "activerecord", "~> #{ar}.0"
    gem "database_cleaner", "~> 1.7.0"
    gem "rspec", "~> 3.9.0"
    gem "sqlite3", "~> 1.3.13"
  end
end

# Note: Rails 6.x requires sqlite3 ~> 1.4
%w[6.0].each do |ar|
  appraise "rspec-3.9-ar-#{ar}-dc-1.8" do
    gem "activerecord", "~> #{ar}.0"
    gem "database_cleaner", "~> 1.8.0"
    gem "database_cleaner-active_record", "~> 1.8.0"
    gem "rspec", "~> 3.9.0"
    gem "sqlite3", "~> 1.4.2"
  end
end
