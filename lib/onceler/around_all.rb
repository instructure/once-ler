# adapted from https://gist.github.com/myronmarston/2005175

module Onceler
  module AroundAll
    class FiberAwareGroup < SimpleDelegator
      def run_examples
        Fiber.yield
      end

      def to_proc
        proc { run_examples }
      end
    end

    def around_all(scope, &block)
      fibers = {}
      prepend_before(:all) do |group|
        fiber = fibers[group] = Fiber.new(&block)
        fiber.resume(FiberAwareGroup.new(group))
      end

      after(:all) do |group|
        fibers.delete(group).resume
      end
    end
  end
end

