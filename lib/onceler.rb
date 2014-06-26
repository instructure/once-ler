require "rspec"
require "onceler/around_all"

module Onceler
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end

  module BasicHelpers
    def onceler
      self.class.onceler
    end

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      include AroundAll

      def let_once(name, &block)
        raise "#let or #subject called without a block" if block.nil?
        onceler(:create)[name] = block
        @current_let_once = name
        define_method(name) { onceler[name] }
      end

      def subject_once(name = nil, &block)
        name ||= :subject
        let_once(name, &block)
        alias_method :subject, name if name != :subject
      end

      def before_once(&block)
        onceler(:create) << block
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

      def onceler(create_own = false)
        if create_own
          @onceler ||= create_onceler!
        else
          @onceler || parent_onceler
        end
      end

      def create_onceler!
        add_onceler_hooks!
        Recorder.new(parent_onceler)
      end

      private

      def parent_onceler
        return unless superclass.respond_to?(:onceler)
        superclass.onceler
      end

      def add_onceler_hooks!
        around_all do |group|
          # TODO: configurable transaction fu (say, if you have multiple
          # conns)
          ActiveRecord::Base.transaction(requires_new: true) do
            group.onceler.record!
            group.run_examples
            raise ActiveRecord::Rollback
          end
        end
        # only the outer-most group needs to do this
        unless parent_onceler
          register_hook :append, :before, :each do
            onceler.replay_into!(self)
          end
        end
      end

      def onceler!
        extend AmbitiousHelpers
      end
    end

    module AmbitiousHelpers
      def before_once?(type)
        super || type == :each || type.nil?
      end

      def let(name, &block)
        let_once(name, &block)
      end

      # TODO NamedSubjectPreventSuper
      def subject(name = nil, &block)
        subject_once(name, &block)
      end

      # remove auto-before'ing of ! methods, since we memoize our own way
      def let!(name, &block)
        let(name, &block)
      end

      def subject!(name = nil, &block)
        subject(name, &block)
      end

      # make sure we have access to subsequently added methods when
      # recording (not just `lets'). note that this really only works
      # for truly functional methods with no external dependencies. e.g.
      # methods that add stubs or set instance variables will not work
      # while recording
      def method_added(method_name)
        return if method_name == @current_let_once
        onceler = onceler(:create)
        proxy = onceler.helper_proxy ||= new
        onceler.helper_methods[method_name] ||= Proc.new do |*args|
          proxy.send method_name, *args
        end
      end
    end
  end

  class BlankTape
    def initialize(modules)
      modules.each { |mod| extend mod }
      @__retvals = {}
      @__retvals_recorded = {} # we might override an inherited one, so we need to differentiate
    end

    def __prepare_recording(recording)
      method = recording.name
      define_singleton_method(method) do
        if @__retvals_recorded[method]
          @__retvals[method]
        else
          @__retvals_recorded[method] = true
          @__retvals[method] = __record(recording)
        end
      end
    end

    def __record(recording)
      instance_eval(&recording.block)
    end

    def __ivars
      ivars = instance_variables - [:@__retvals, :@__retvals_recorded]
      ivars.inject({}) do |hash, key|
        val = instance_variable_get(key)
        hash[key] = val
        hash
      end
    end

    def __data
      [__ivars, @__retvals]
    end

    def copy(mixins)
      copy = self.class.new(mixins)
      copy.copy_from(self)
      copy
    end

    def copy_from(other)
      ivars, @__retvals = Marshal.load(Marshal.dump(other.__data))
      ivars.each do |key, value|
        instance_variable_set(key, value)
      end
      @__retvals.each do |key, value|
        define_singleton_method(key) { value }
      end
    end
  end

  class Recorder
    attr_accessor :tape, :helper_proxy

    def initialize(parent)
      @parent = parent
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
      @tape = @parent ? @parent.tape.copy(mixins) : BlankTape.new(mixins)
      proxy_recordable_methods!

      # we don't know the order named recordings will be called (or if
      # they'll call each other), so prep everything first
      @recordings.each do |recording|
        recording.prepare_medium!(@tape)
      end
      @recordings.each do |recording|
        recording.record_onto!(@tape)
      end
      @data = Marshal.dump(@tape.__data)
    end

    def proxy_recordable_methods!
      # the proxy is used to run non-recordable methods that may be called
      # by ones are recording. since the former could in turn call more of
      # the latter, we need to proxy the other way too
      return unless helper_proxy
      methods = @named_recordings
      reverse_proxy = @tape
      helper_proxy.instance_eval do
        methods.each do |method|
          define_singleton_method(method) { reverse_proxy.send(method) }
        end
      end
    end

    def helper_methods
      @helper_methods ||= {}
    end

    def mixins
      mixins = (@parent ? @parent.mixins : Onceler.configuration.modules).dup
      if methods = @helper_methods
        mixin = Module.new do
          methods.each do |key, method|
            define_method(key, &method)
          end
        end
        mixins.push mixin
      end
      mixins
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

  class Configuration
    def modules
      @modules ||= []
    end

    def include(mod)
      modules << mod
    end
  end
end

RSpec.configure do |c|
  c.include Onceler::BasicHelpers
end

module ActiveRecord::TestFixtures
  def teardown_fixtures; end # we manage it ourselves
end
