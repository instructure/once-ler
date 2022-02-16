require "onceler/recordable"

module Onceler
  class << self
    attr_accessor :recording

    def recording?
      @recording
    end
  end

  class Recorder
    attr_accessor :tape

    def initialize(group_class)
      @group_class = group_class
      @recordings = []
      @named_recordings = []
      @arounds = []
    end

    def parent_tape
      parent.tape || parent.parent_tape if parent
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

    def add_around(block)
      @arounds.unshift(block)
    end

    def arounds
      (parent ? parent.arounds : []) + @arounds
    end

    def record!
      Onceler.recording = true
      @tape = @group_class.new
      @tape.setup_fixtures
      @tape.send :extend, Recordable
      @tape.copy_from(parent_tape) if parent_tape

      run_before_hooks(:record, @tape)
      # we don't know the order named recordings will be called (or if
      # they'll call each other), so prep everything first
      @recordings.each do |recording|
        recording.prepare_medium!(@tape)
      end

      # wrap the before in a lambda
      stack = -> do
        @recordings.each do |recording|
          recording.record_onto!(@tape)
        end
      end
      # and then stack each around block on top
      arounds.inject(stack) do |old_stack, hook|
        -> { @tape.instance_exec(old_stack, &hook) }
      end.call

      run_after_hooks(:record, @tape)
      @data = @tape.__data
    ensure
      Onceler.recording = false
    end

    def reset!
      run_before_hooks(:reset)
      @tape&.teardown_fixtures
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
        parent.run_after_hooks(scope, context)
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
