# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = "once-ler"
  s.version = "2.3.0"
  s.summary = "rspec supercharger"
  s.description = "once-ler supercharges your let's and before's with the performance of before(:all)"
  s.license = "MIT"

  s.required_ruby_version     = ">= 3.3"
  s.required_rubygems_version = ">= 2.6.0"

  s.author            = "Jon Jensen"
  s.email             = "jon@instructure.com"
  s.homepage          = "http://github.com/instructure/once-ler"
  s.metadata["rubygems_mfa_required"] = "true"

  s.files = %w[README.md] + Dir["lib/**/*.rb"]

  s.add_dependency "activerecord", ">= 7.1", "< 8.2"
  s.add_dependency "rspec", ">= 3.6"
  s.add_dependency "rspec-rails", ">= 4.0"
end
