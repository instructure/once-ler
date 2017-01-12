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
      # top-level recorders don't inherit anything, so we always want to return true
      return true unless @__inherited_cache
      # need to do both types of comparison, i.e. it's the same object in
      # memory (not reassigned), and nothing about it has been changed
      return true unless @__inherited_values[key].equal?(val)
      return true unless __values_equal?(@__inherited_cache[key], val)
      false
    end

    def __values_equal?(obj1, obj2)
      if ActiveRecord::Base === obj1 && ActiveRecord::Base === obj2
        cache_key = [obj1, obj2]
        return @__comparison_cache[cache_key] if @__comparison_cache.key?(cache_key)
        # so as to avoid cycles while traversing AR associations
        @__comparison_cache[cache_key] = true
        @__comparison_cache[cache_key] = obj1.attributes == obj2.attributes &&
                                         __associations_equal?(obj1, obj2)
      else
        obj1 == obj2
      end
    end

    # if a nested once block updates an inherited object's associations,
    # we want to know about it
    def __associations_equal?(obj1, obj2)
      cache1 = obj1.instance_variable_get(:@association_cache)
      cache2 = obj2.instance_variable_get(:@association_cache)
      cache1.size == cache2.size &&
      cache1.all? { |k, v| cache2.key?(k) && __values_equal?(v.target, cache2[k].target) }
    end

    def __data(inherit = false)
      @__data ||= {}
      @__data[inherit] ||= begin
        @__comparison_cache = {}
        data = [__ivars(inherit), __retvals(inherit)]
        begin
          data = Marshal.dump(data)
        rescue TypeError
          data.each do |hash|
            hash.each do |key, val|
              find_dump_error(key, val)
            end
          end
          raise # find_dump_error should have re-raised, but just in case...
        end
        @__comparison_cache = nil
        data
      end
    end

    def find_dump_error(key, val, prefix = "")
      begin
        Marshal.dump(val)
      rescue TypeError

        # see if anything inside val can't be dumped...
        sub_prefix = "#{prefix}#{key} (#<#{val.class}>) => "

        # instance var?
        val.instance_variables.each do |k|
          v = val.instance_variable_get(k)
          find_dump_error(k, v, sub_prefix)
        end

        # hash key/value?
        val.each_pair do |k, v|
          find_dump_error("hash key #{k}", k, sub_prefix)
          find_dump_error("[#{k.inspect}]", v, sub_prefix)
        end if val.respond_to?(:each_pair)

        # array element?
        val.each_with_index do |v, i|
          find_dump_error("[#{i}]", v, sub_prefix)
        end if val.respond_to?(:each_with_index)

        # guess it's val proper
        raise TypeError.new("Unable to dump #{prefix}#{key} (#<#{val.class}>) in #{self.class.metadata[:location]}: #{$!}")
      end
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

