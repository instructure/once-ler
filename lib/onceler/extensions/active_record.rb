require "active_record"
require "rails/version"

# monkey-patch this to not clear connections so that we don't lose our
# transactions

module ActiveRecord::TestFixtures
  def teardown_fixtures
    if ::Rails.version < "7.2"
      if run_in_transaction?
        ActiveSupport::Notifications.unsubscribe(@connection_subscriber) if @connection_subscriber
        @fixture_connections.each do |connection|
          connection.rollback_transaction if connection.transaction_open?
          connection.pool.lock_thread = false
        end
        @fixture_connections.clear
        teardown_shared_connection_pool
      else
        ActiveRecord::FixtureSet.reset_cache
      end
    else
      if run_in_transaction?
        teardown_transactional_fixtures
      else
        ActiveRecord::FixtureSet.reset_cache
        invalidate_already_loaded_fixtures
      end
    end
  end
end
