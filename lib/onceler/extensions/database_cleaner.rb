require "database_cleaner/active_record/transaction"

class DatabaseCleaner::ActiveRecord::Transaction
  include ::Onceler::Transactions

  def start
    begin_transaction(connection_class.connection)
  end

  def clean
    rollback_transaction(connection_class.connection)
  end
end
