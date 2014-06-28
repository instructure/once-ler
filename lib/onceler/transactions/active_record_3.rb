module Onceler
  module Transactions
    def begin_transaction(conn)
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
      else
        conn.rollback_to_savepoint
      end
    end
  end
end

