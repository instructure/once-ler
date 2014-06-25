require "onceler/around_all"

module Onceler
  module ClassMethods
    module BasicHelpers
      include AroundAll

      def let_once(name, &block)
        raise "#let or #subject called without a block" if block.nil?
        recorder[name] = block
        # TODO: prevent super calls, a la NamedSubjectPreventSuper
        define_method(name) { recorder[name] }
      end

      def before_once(&block)
        recorder << block
      end

      def before_once?(type)
        type == :once
      end

      def before(*args, &block)
        if before_once?(args.first)
          before_once(&block)
        else
          super(*args, &block)
        end
      end

      def recorders
        return [] if self == RSpec::Core::ExampleGroup
        superclass.recorders + (@recorder ? [@recorder] : [])
      end

      private

      def recorder
        unless @recorder
          @recorder = Recorder.new
          add_recorder_hooks!
        end
        @recorder
      end

      def record_all!
        # TODO: can we somehow record just once for the group even if it
        # has nested groups?
        tape = BlankTape.new
        recorders.each do |record|
          recorder.record_onto!(tape)
        end
        group.run_examples
      end

      def replay_all!
        recorders.each do |recorder|
          recorder.replay_into!(self)
        end
      end

      def add_recorder_hooks!
        return if recorders.present? # parent group already did it

        around_all do |group|
          # TODO: configurable transaction fu (say, if you have multiple
          # conns)
          ActiveRecord::Base.transaction do
            group.record_all!
          end
        end
        register_hook :append, :before, :each do
          example_group.replay_all!
        end
      end

      def onceler!
        include AmbitiousHelpers
      end
    end

    module AmbitiousHelpers
      def before_once?(type)
        super || type == :each || type.nil?
      end

      def let(name, &block)
        let_once(name, block)
      end
      # don't need to redefine subject, since it just calls let

      # remove auto-before'ing of ! methods, since we memoize our own way
      def let!(name, &block)
        let(name, &block)
      end

      def subject!(name = nil, &block)
        subject(name, &block)
      end
    end
  end

  class BlankTape
    def initialize
      @__retvals = {}
    end

    def __prepare_recording(recording)
      method = recording.name
      define_method(method) do
        if @__retvals.key?(method)
          @__retvals[method]
        else
          @__retvals[method] = __record(recording)
        end
      end
    end

    def __record(recording)
      instance_eval(&recording.block)
    end

    def __ivars
      ivars = instance_variables - [:@__retvals]
      ivars.inject({}) { |hash, key|
        val = instance_variable_get(key)
        val = val.dup if val.duplicable?
        hash[key] = val
        hash
      }
    end

    def __data
      [__ivars, __retvals]
    end
  end

  class Recorder
    attr_accessor :instance

    def initialize
      @recordings = []
    end

    def <<(block)
      @recordings << Recording.new(block)
    end

    def []=(name, block)
      @recordings << NamedRecording.new(block, name)
    end

    def [](name)
      @retvals[name]
    end

    def record_onto!(tape)
      # we don't know the order named recordings will be called (or if
      # they'll call each other), so prep everything first
      @recordings.each do |recording|
        recording.prepare_medium!(tape)
      end
      @recordings.each do |recording|
        recording.record_onto!(tape)
      end
      @data = Marshal.dump(tape.__data)
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
      @instance = instance
      reconsitute_data!
      ivars.each do |key, value|
        instance.instance_variable_set(key, value)
      end
    end
  end

  class Recording
    attr_reader :block

    def initialize(block)
      @block = block
    end

    def prepare_medium(tape); end

    def record_onto!(tape)
      tape.__record(self)
    end
  end

  class NamedRecording < Recording
    attr_reader :name

    def initialize(block, name = nil)
      super
      @name = name
    end

    def prepare_medium!(tape)
      tape.__prepare_recording(self)
    end

    def record_onto!(tape)
      tape.send(method)
    end
  end
end

