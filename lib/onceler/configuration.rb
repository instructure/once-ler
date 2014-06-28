module Onceler
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end

  class Configuration
    def modules
      @modules ||= []
    end

    def include(mod)
      modules << mod
    end

    def before(scope, &block)
      callbacks[scope][:before] << block
    end

    def callbacks
      @callbacks ||= Hash.new do |scopes, scope|
        scopes[scope] = Hash.new do |timings, timing|
          timings[timing] = []
        end
      end
    end

    def run_callbacks(scope, timing)
      callbacks[scope][timing].each(&:call)
    end
  end
end
