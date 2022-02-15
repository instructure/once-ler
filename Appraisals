# Note: Rails 6.x requires sqlite3 ~> 1.4
%w[6.0 6.1].each do |ar|
  appraise "rspec-3.9-ar-#{ar}-dc-2.0" do
    gem "activerecord", "~> #{ar}.0"
    gem "database_cleaner", "~> 2.0"
    gem "database_cleaner-active_record", "~> 2.0"
    gem "rspec", "~> 3.10.0"
    gem "sqlite3", "~> 1.4.2"
  end
end
