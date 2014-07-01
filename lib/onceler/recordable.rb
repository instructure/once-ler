module Onceler
  module Recordable
    def self.extended(instance)
      instance.instance_eval do
        @__retvals = {}
        @__inherited_retvals = {}
        @__ignore_ivars = instance_variables
      end
    end

    def __prepare_recording(recording)
      method = recording.name
      define_singleton_method(method) do
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

    def __retvals(inherit = false)
      retvals = @__inherited_retvals.merge(@__retvals)
      retvals.inject({}) do |hash, (key, val)|
        hash[key] = val if __mutated?(key, val) || inherit
        hash
      end
    end

    def __ivars(inherit = false)
      ivars = instance_variables - @__ignore_ivars
      ivars.inject({}) do |hash, key|
        if key.to_s !~ /\A@__/
          val = instance_variable_get(key)
          hash[key] = val if __mutated?(key, val) || inherit
        end
        hash
      end
    end

    # we don't include inherited stuff in __data, because we might need to
    # interleave things from an intermediate before(:each) at run time
    def __mutated?(key, val)
      return true unless @__inherited_cache
      # need to do both types of comparison, i.e. it's the same object in
      # memory (not reassigned), and nothing about it has been changed
      return false if @__inherited_values.equal?(val)
      return false if @__inherited_cache[key] == val
      true
    end

    def __data(inherit = false)
      @__data ||= {}
      @__data[inherit] ||= Marshal.dump([__ivars(inherit), __retvals(inherit)])
    end

    def copy_from(other)
      # need two copies of things for __mutated? checks (see above)
      @__inherited_cache = Marshal.load(other.__data(:inherit)).inject(&:merge)
      ivars, retvals = Marshal.load(other.__data(:inherit))
      @__inherited_retvals = retvals
      @__inherited_values = ivars.merge(retvals)
      ivars.each do |key, value|
        instance_variable_set(key, value)
      end
      retvals.each do |key, value|
        define_singleton_method(key) { value }
      end
    end
  end
end

