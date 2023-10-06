# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'once-ler'
  s.version = '2.0.1'
  s.summary = 'rspec supercharger'
  s.description = "once-ler supercharges your let's and before's with the performance of before(:all)"
  s.license = 'MIT'

  s.required_ruby_version     = '>= 2.7'
  s.required_rubygems_version = '>= 2.6.0'

  s.author            = 'Jon Jensen'
  s.email             = 'jon@instructure.com'
  s.homepage          = 'http://github.com/instructure/once-ler'

  s.files = %w(README.md) + Dir['lib/**/*.rb']

  s.add_dependency 'activerecord', '>= 6.0', '< 7.2'
  s.add_dependency 'rspec', '>= 3.6'
  s.add_dependency 'rspec-rails', '>= 4.0'

  s.add_development_dependency 'appraisal', '~> 2.3.0'
  s.add_development_dependency 'debug'

  s.add_development_dependency 'database_cleaner', '~> 2.0'
  s.add_development_dependency 'database_cleaner-active_record', '~> 2.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'sqlite3', '~> 1.4.2'
end
