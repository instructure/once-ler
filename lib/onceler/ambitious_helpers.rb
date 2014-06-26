module Onceler
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
