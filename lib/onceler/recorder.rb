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
      @retvals[name]
    end

    def record!
      Onceler.recording = true
      begin_transactions!
      @tape = @group_class.new
      @tape.send :extend, Recordable
      if parent = @group_class.parent_onceler
        @tape.copy_from(parent.tape)
      end

      # we don't know the order named recordings will be called (or if
      # they'll call each other), so prep everything first
      @recordings.each do |recording|
        recording.prepare_medium!(@tape)
      end
      @recordings.each do |recording|
        recording.record_onto!(@tape)
      end
      @data = @tape.__data
    ensure
      Onceler.recording = false
    end

    def reset!
      rollback_transactions!
    end

    def reconsitute_data!
      @ivars, @retvals = Marshal.load(@data)
      identity_map = {}
      reidentify!(@ivars, identity_map)
      reidentify!(@retvals, identity_map)
    end

    def reidentify!(hash, identity_map)
      hash.each do |key, value|
        if identity_map.key?(value)
          hash[key] = identity_map[value]
        else
          identity_map[value] = value
        end
      end
    end

    def replay_into!(instance)
      reconsitute_data!
      @ivars.each do |key, value|
        instance.instance_variable_set(key, value)
      end
    end

    # TODO: configurable transaction fu (say, if you have multiple
    # conns)
    def transaction_classes
      [ActiveRecord::Base]
    end

    def begin_transactions!
      Onceler.open_transactions += 1
      transaction_classes.each do |klass|
        begin_transaction(klass.connection)
      end
    end

    def rollback_transactions!
      transaction_classes.each do |klass|
        rollback_transaction(klass.connection)
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
