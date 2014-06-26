# adapted from https://gist.github.com/myronmarston/2005175
require 'delegate'
require 'fiber'

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

    def around_all(&block)
      fibers = []
      prepend_before(:all) do |group|
        fiber = Fiber.new(&block)
        fibers << fiber
        fiber.resume(FiberAwareGroup.new(group))
      end

      after(:all) do |group|
        fiber = fibers.pop
        fiber.resume if fiber.alive?
      end
    end
  end
end

