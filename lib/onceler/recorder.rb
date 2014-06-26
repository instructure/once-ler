require "onceler/blank_tape"

module Onceler
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
end
