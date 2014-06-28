require "onceler/transactions"

# monkey-patch these to use savepoints (if necessary)

module ActiveRecord::TestFixtures
  include Onceler::Transactions

  def setup_fixtures
    return unless defined?(ActiveRecord) && !ActiveRecord::Base.configurations.blank?

    if pre_loaded_fixtures && !use_transactional_fixtures
      raise RuntimeError, 'pre_loaded_fixtures requires use_transactional_fixtures'
    end

    @fixture_cache = {}
    @@already_loaded_fixtures ||= {}

    # Load fixtures once and begin transaction.
    if run_in_transaction?
      if @@already_loaded_fixtures[self.class]
        @loaded_fixtures = @@already_loaded_fixtures[self.class]
      else
        load_fixtures
        @@already_loaded_fixtures[self.class] = @loaded_fixtures
      end
      ### ONCELER'd
      begin_transaction(ActiveRecord::Base.connection)
    # Load fixtures for every test.
    else
      Fixtures.reset_cache
      @@already_loaded_fixtures[self.class] = nil
      load_fixtures
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
    if run_in_transaction? && ActiveRecord::Base.connection.open_transactions != 0
      ### ONCELER'd
      rollback_transaction(ActiveRecord::Base.connection)
    end
    ActiveRecord::Base.clear_active_connections!
  end
end
