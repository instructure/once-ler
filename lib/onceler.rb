module Onceler
  module ClassMethods
    module BasicHelpers
      def let_once(name, &block)
        raise "#let or #subject called without a block" if block.nil?
        onceler[name] = block
        # TODO: prevent super calls, a la NamedSubjectPreventSuper
        define_method(name) { onceler[name] }
      end

      def before_once(&block)
        onceler << block
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

      def add_recorder_hooks!
        return if recorders.present? # parent group already did it
        # TODO: can we somehow do it just once for the group even if it
        # has nested groups?
        around_all do
          # TODO: configurable transaction fu (say, if you have multiple
          # conns)
          ActiveRecord::Base.transaction do |group|
            group.recorders.map(&:record!)
            group.run_examples
            group.recorders.map(&:reset!)
          end
        end
        register_hook :append, :before, :each do
          recorder.instance = self
          recorder.replay_blocks!
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

      # remove auto-before'ing of ! methods, since we do it our own way
      def let!(name, &block)
        let(name, &block)
      end

      def subject!(name = nil, &block)
        subject(name, &block)
      end
    end
  end

  class Recorder
    attr_accessor :instance

    def initialize
      @all = []
      @unnamed = []
      @named = {}
    end

    def register(block)
      recording = Recording.new(block, bucket)
      @all << recording
      block
    end

    def <<(block)
      @unnamed << register(block)
    end

    def record!
      # how to share across examples?
      canvas = BasicObject.new
      @all.each do |recording|
        recording.record!(canvas)
      end
    end

    def reset!
      @all.each(&:reset!)
    end

    def replay_unnamed!
      @unnamed.each do |recording|
        recording.replay_into!(@instance)
      end
    end

    def []=(name, block)
      @named[name] = register(recording)
    end

    def [](name)
      @named[name].replay_into!(@instance)
    end
  end

  class Recording
    def record!

    end

    def replay_into!(instance)
      @ivars.each do |key, value|
        instance.instance_variable_set(key, value)
      end
      @retval
    end
  end
end

