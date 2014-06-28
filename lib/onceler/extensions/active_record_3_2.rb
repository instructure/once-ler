require "onceler/transactions"

# monkey-patch these to use savepoints (if necessary)

module ActiveRecord::TestFixtures
  include ::Onceler::Transactions

  def setup_fixtures
    return unless !ActiveRecord::Base.configurations.blank?

    if pre_loaded_fixtures && !use_transactional_fixtures
      raise RuntimeError, 'pre_loaded_fixtures requires use_transactional_fixtures'
    end

    @fixture_cache = {}
    @fixture_connections = []
    @@already_loaded_fixtures ||= {}

    # Load fixtures once and begin transaction.
    if run_in_transaction?
      if @@already_loaded_fixtures[self.class]
        @loaded_fixtures = @@already_loaded_fixtures[self.class]
      else
        @loaded_fixtures = load_fixtures
        @@already_loaded_fixtures[self.class] = @loaded_fixtures
      end
      @fixture_connections = enlist_fixture_connections
      @fixture_connections.each do |connection|
        ### ONCELER'd
        begin_transaction(connection)
      end
    # Load fixtures for every test.
    else
      ActiveRecord::Fixtures.reset_cache
      @@already_loaded_fixtures[self.class] = nil
      @loaded_fixtures = load_fixtures
    end

    # Instantiate fixtures for every test if requested.
    instantiate_fixtures if use_instantiated_fixtures
  end

  def teardown_fixtures
    return unless defined?(ActiveRecord) && !ActiveRecord::Base.configurations.blank?

    unless run_in_transaction?
      ActiveRecord::Fixtures.reset_cache
    end

    # Rollback changes if a transaction is active.
    if run_in_transaction?
      @fixture_connections.each do |connection|
        if connection.open_transactions != 0
          ### ONCELER'd
          rollback_transaction(connection)
        end
      end
      @fixture_connections.clear
    end
    ActiveRecord::Base.clear_active_connections!
  end
end

