module Onceler
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end

  class Configuration
    def before(scope, &block)
      hooks[:before][scope] << block
    end

    def after(scope, &block)
      hooks[:before][scope] << block
    end

    def hooks
      @hooks ||= {
        before: {record: [], reset: []},
        after:  {record: [], reset: []}
      }
    end

    def run_hooks(timing, scope, context)
      hooks[timing][scope].each do |hook|
        context ? context.instance_eval(&hook) : hook.call
      end
    end
  end
end
