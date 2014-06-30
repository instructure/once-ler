module Onceler
  module Recordable
    def self.extended(instance)
      instance.instance_eval do
        @__retvals = {}
        @__retvals_recorded = {} # we might override an inherited one, so we need to differentiate
        @__ignore_ivars = instance_variables
      end
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

    def __retvals
      @__retvals.slice(*@__retvals_recorded.keys)
    end

    def __ivars
      ivars = instance_variables - @__ignore_ivars
      ivars.inject({}) do |hash, key|
        if key.to_s !~ /\A@__/
          val = instance_variable_get(key)
          hash[key] = val unless __inherited_ivar?(key, val)
        end
        hash
      end
    end

    def __inherited_ivar?(key, val)
      return false unless @__inherited_ivar_cache
      # need to do both types of comparison, i.e. it's the same object in
      # memory, and nothing about it has been changed
      @__inherited_ivar_cache[key] == val && @__inherited_ivars.equal?(val)
    end

    def __data
      @__data ||= Marshal.dump([__ivars, __retvals])
    end

    def copy_from(other)
      @__inherited_ivar_cache = Marshal.load(other.__data).first
      @__inherited_ivars, @__retvals = Marshal.load(other.__data)
      @__inherited_ivars.each do |key, value|
        instance_variable_set(key, value)
      end
      @__retvals.each do |key, value|
        define_singleton_method(key) { value }
      end
    end
  end
end

