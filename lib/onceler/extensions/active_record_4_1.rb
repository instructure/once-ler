# monkey-patch this to not clear connections so that we don't lose our
# transactions

module ActiveRecord::TestFixtures
  def teardown_fixtures
    # Rollback changes if a transaction is active.
    if run_in_transaction?
      @fixture_connections.each do |connection|
        connection.rollback_transaction if connection.transaction_open?
      end
      @fixture_connections.clear
    else
      ActiveRecord::FixtureSet.reset_cache
    end
    ### ONCELER'd
  end
end
