RSPEC_VERSIONS=%w[2.14 3.0 3.1]
AR_VERSIONS=%w[3.1 3.2 4.0 4.1]

RSPEC_VERSIONS.each do |rspec|
  AR_VERSIONS.each do |ar|
    appraise "rspec-#{rspec}-ar-#{ar}" do
      gem "activerecord", "~> #{ar}.0"
      gem "rspec", "~> #{rspec}.0"
    end

    appraise "rspec-#{rspec}-ar-edge" do
      gem "activerecord", github: "rails/rails"
      gem "rspec", "~> #{rspec}.0"
    end
  end
end
