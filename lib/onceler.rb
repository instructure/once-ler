module Onceler
  # need:
  #
  # before(:all) to record once blocks
  # * can we somehow do it just once for the group even if there is nesting?
  #
  # before(:each) to replay recordings
  module ClassMethods
    module BasicHelpers
      def let_once(name, &block)
        onceler.add name, &block
        raise "#let or #subject called without a block" if block.nil?
        # TODO: prevent super calls, a la NamedSubjectPreventSuper
        define_method(name) { onceler.replay(name) }
      end

      def before_once(&block)
        onceler.add &block
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

      def onceler!
        include AmbitiousHelpers
      end

      private
      def onceler
        @onceler ||= Recorder.new
      end
    end

    module AmbitiousHelpers
      def before_once?(type)
        super || type == :each || type.nil?
      end

      def let(name, &block)
        let_once(name, block)
      end
      # don't need to redefine subject, since it just calls let

      # remove auto-before'ing of ! methods, since we do it our own way
      def let!(name, &block)
        let(name, &block)
      end

      def subject!(name = nil, &block)
        subject(name, &block)
      end
    end
  end

  class Recorder
    def initialize
      @recordings = []
      @named_recordings = {}
    end

    def add(name = nil, &block)
    end
  end
end

