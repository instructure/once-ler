require "onceler/ambitious_helpers"
require "onceler/recorder"

module Onceler
  module BasicHelpers
    def onceler
      self.class.onceler
    end

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def let_once(name, &block)
        raise "#let or #subject called without a block" if block.nil?
        onceler(:create)[name] = block
        @current_let_once = name
        define_method(name) { onceler[name] }
      end

      def subject_once(name = nil, &block)
        name ||= :subject
        let_once(name, &block)
        alias_method :subject, name if name != :subject
      end

      def before_once(&block)
        onceler(:create) << block
      end

      def before_once?(type)
        type == :once
      end

      def before(*args, &block)
        if before_once?(args.first)
          before_once(&block)
        else
          super(*args, &block)
        end
      end

      def onceler(create_own = false)
        if create_own
          @onceler ||= create_onceler!
        else
          @onceler || parent_onceler
        end
      end

      def create_onceler!
        add_onceler_hooks!
        Recorder.new(parent_onceler)
      end

      private

      def parent_onceler
        return unless superclass.respond_to?(:onceler)
        superclass.onceler
      end

      def add_onceler_hooks!
        prepend_before(:all) do |group|
          group.onceler.record!
        end

        after(:all) do |group|
          group.onceler.reset!
        end

        # only the outer-most group needs to do this
        unless parent_onceler
          append_before :each do
            onceler.replay_into!(self)
          end
        end
      end

      def onceler!
        extend AmbitiousHelpers
      end
    end
  end
end
