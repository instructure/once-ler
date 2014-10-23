require "rspec"
require "onceler/basic_helpers"
require "onceler/configuration"
require "onceler/extensions/active_record"
if defined?(DatabaseCleaner)
  require "onceler/extensions/database_cleaner"
end
