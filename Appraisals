RSPEC_VERSIONS=%w[3.0 3.5]
AR_VERSIONS=%w[4.0 4.2 5.0]

RSPEC_VERSIONS.each do |rspec|
  AR_VERSIONS.each do |ar|
    appraise "rspec-#{rspec}-ar-#{ar}" do
      gem "activerecord", "~> #{ar}.0"
      gem "rspec", "~> #{rspec}.0"
    end
  end
end

appraise "rspec-#{RSPEC_VERSIONS.last}-ar-edge" do
  gem "activerecord", github: "rails/rails"
  gem "rspec", "~> #{RSPEC_VERSIONS.last}.0"
end
