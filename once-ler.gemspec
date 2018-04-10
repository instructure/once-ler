# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'once-ler'
  s.version = '0.1.2'
  s.summary = 'rspec supercharger'
  s.description = "once-ler supercharges your let's and before's with the performance of before(:all)"

  s.required_ruby_version     = '>= 1.9.3'
  s.required_rubygems_version = '>= 1.3.5'

  s.author            = 'Jon Jensen'
  s.email             = 'jon@instructure.com'
  s.homepage          = 'http://github.com/instructure/once-ler'

  s.files = %w(README.md) + Dir['lib/**/*rb'] + Dir['test/**/*.rb']
  s.add_dependency('activerecord', '>= 4.0')
  s.add_dependency('rspec', '>= 3.0')
end
