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
  end
end
