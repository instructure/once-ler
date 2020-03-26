require "rspec"
require "rubygems"

require "onceler/basic_helpers"
require "onceler/configuration"
require "onceler/extensions/active_record"

if defined?(DatabaseCleaner)
  unless !DatabaseCleaner.const_defined?("VERSION") ||
    Gem::Requirement.new("~> 1.7").satisfied_by?(Gem::Version.new(DatabaseCleaner::VERSION))
    raise "Onceler in only compatible with DatabaseCleaner ~> 1.7."
  end
  require "onceler/extensions/database_cleaner"
end
