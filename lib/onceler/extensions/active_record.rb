require "active_record"

if ActiveRecord::VERSION::STRING >= "4.1."
  require "onceler/extensions/active_record_4_1"
else
  require "onceler/extensions/active_record_4_0"
end
