module Onceler
  module Transactions
    def begin_transaction(conn)
      unless conn.instance_variable_get(:@_current_transaction_records)
        conn.instance_variable_set(:@_current_transaction_records, [])
      end
      if conn.open_transactions == 0
        conn.transaction_joinable = false
        conn.begin_db_transaction
      else
        conn.create_savepoint
      end
      conn.increment_open_transactions
    end

    def rollback_transaction(conn)
      conn.decrement_open_transactions
      if conn.open_transactions == 0
        conn.rollback_db_transaction
        conn.send :rollback_transaction_records, true
      else
        conn.rollback_to_savepoint
        conn.send :rollback_transaction_records, false
      end
    end
  end
end

