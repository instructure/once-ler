require "onceler/recordable"
require "onceler/transactions"

module Onceler
  class << self
    def open_transactions
      @open_transactions ||= 0
    end

    def open_transactions=(val)
      @open_transactions = val
    end

    attr_accessor :recording

    def recording?
      @recording
    end
  end

  class Recorder
    include Transactions

    attr_accessor :tape

    def initialize(group_class)
      @group_class = group_class
      @recordings = []
      @named_recordings = []
    end

    def <<(block)
      @recordings << Recording.new(block)
    end

    def []=(name, block)
      @named_recordings << name
      @recordings << NamedRecording.new(block, name)
    end

    def [](name)
      if @retvals && @retvals.key?(name)
        @retvals[name]
      elsif parent
        parent[name]
      end
    end

    def record!
      Onceler.recording = true
      begin_transactions!
      @tape = @group_class.new
      @tape.send :extend, Recordable
      if parent = @group_class.parent_onceler
        @tape.copy_from(parent.tape)
      end

      run_before_hooks(:record, @tape)
      # we don't know the order named recordings will be called (or if
      # they'll call each other), so prep everything first
      @recordings.each do |recording|
        recording.prepare_medium!(@tape)
      end
      @recordings.each do |recording|
        recording.record_onto!(@tape)
      end
      run_after_hooks(:record, @tape)
      @data = @tape.__data
    ensure
      Onceler.recording = false
    end

    def reset!
      run_before_hooks(:reset)
      rollback_transactions!
      run_after_hooks(:reset)
    end

    def parent
      @group_class.parent_onceler
    end

    def hooks
      @hooks ||= {
        before: {record: [], reset: []},
        after:  {record: [], reset: []}
      }
    end

    def run_before_hooks(scope, context = nil)
      if parent
        parent.run_before_hooks(scope, context)
      else
        Onceler.configuration.run_hooks(:before, scope, context)
      end
      hooks[:before][scope].each do |hook|
        context ? context.instance_eval(&hook) : hook.call
      end
    end

    def run_after_hooks(scope, context = nil)
      hooks[:after][scope].each do |hook|
        context ? context.instance_eval(&hook) : hook.call
      end
      if parent
        parent.run_before_hooks(scope, context)
      else
        Onceler.configuration.run_hooks(:after, scope, context)
      end
    end

    def replay_into!(instance)
      @ivars, @retvals = Marshal.load(@data)
      @ivars.each do |key, value|
        instance.instance_variable_set(key, value)
      end
    end

    def transactional_connections
      @group_class.onceler_connections
    end

    def begin_transactions!
      Onceler.open_transactions += 1
      transactional_connections.each do |connection|
        begin_transaction(connection)
      end
    end

    def rollback_transactions!
      transactional_connections.each do |connection|
        rollback_transaction(connection)
      end
    ensure
      Onceler.open_transactions -= 1
    end
  end

  class Recording
    attr_reader :block

    def initialize(block)
      @block = block
    end

    def prepare_medium!(tape); end

    def record_onto!(tape)
      tape.__record(self)
    end
  end

  class NamedRecording < Recording
    attr_reader :name

    def initialize(block, name = nil)
      super(block)
      @name = name
    end

    def prepare_medium!(tape)
      tape.__prepare_recording(self)
    end

    def record_onto!(tape)
      tape.send(@name)
    end
  end
end
