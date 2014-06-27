require "active_record"

if ActiveRecord::VERSION::STRING >= "4.1."
  require "onceler/extensions/active_record_4_1"
elsif ActiveRecord::VERSION::STRING >= "4.0."
  require "onceler/extensions/active_record_4_0"
elsif ActiveRecord::VERSION::STRING >= "3.2."
  require "onceler/extensions/active_record_3_2"
else
  require "onceler/extensions/active_record_3_0"
end
