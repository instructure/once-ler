module Onceler
  module Transactions
    def begin_transaction(conn)
      conn.begin_transaction joinable: false
    end

    def rollback_transaction(conn)
      conn.rollback_transaction
    end
  end
end
