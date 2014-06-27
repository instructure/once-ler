require "active_record"
if ActiveRecord::VERSION::MAJOR >= 4
  require "onceler/transactions/active_record_4"
else
  require "onceler/transactions/active_record_3"
end

