# frozen_string_literal: true

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
        raise ArgumentError, "wrong number of arguments (0 for 1)" if name.nil?
        raise "#let or #subject called without a block" if block.nil?

        onceler(create_own: true)[name] = block
        add_onceler_hooks!
        @current_let_once = name
        define_method(name) { onceler[name] }
      end

      # TODO: NamedSubjectPreventSuper
      def subject_once(name = nil, &)
        name ||= :subject
        let_once(name, &)
        alias_method :subject, name if name != :subject
      end

      def around_once(&block)
        onceler(create_own: true).add_around(block)
        add_onceler_hooks!
      end

      def before_once(&block)
        onceler(create_own: true) << block
        add_onceler_hooks!
      end

      def once_scopes
        [:once]
      end

      # add second scope argument to explicitly differentiate between
      # :each / :once
      %i[let let! subject subject!].each do |method|
        once_method = :"#{method.to_s.delete_suffix("!")}_once"
        define_method(method) do |name = nil, scope = nil, &block|
          if once_scopes.include?(scope)
            send once_method, name, &block
          else
            super(name, &block)
          end
        end

        # set up let_each, etc.
        each_method = method.to_s
        bang = each_method.delete_suffix!("!")
        each_method = :"#{each_method}_each#{"!" if bang}"
        define_method(each_method) do |name = nil, &block|
          send method, name, :each, &block
        end
      end

      def before(*args, &block)
        scope = args.first
        case scope
        when :record, :reset
          onceler(create_own: true).hooks[:before][scope] << block
        when *once_scopes
          before_once(&block)
        else
          super
        end
      end

      def after(*args, &block)
        scope = args.first
        case scope
        when :record, :reset
          onceler(create_own: true).hooks[:after][scope] << block
        else
          super
        end
      end

      def around(*args, &)
        scope = args.first
        case scope
        when *once_scopes
          around_once(&)
        when :once_and_each
          around_once(&)
          around(:each, &)
        else
          super
        end
      end

      def onceler(create_own: false)
        if create_own
          @onceler ||= Recorder.new(self)
        else
          @onceler || parent_onceler
        end
      end

      def parent_onceler
        return unless superclass.respond_to?(:onceler)

        superclass.onceler
      end

      private

      def add_onceler_hooks!
        return if @onceler_hooks_added

        @onceler_hooks_added = true

        before(:all) do |group|
          group.onceler.record!
        end

        after(:all) do |group|
          group.onceler.reset!
        end

        group_class = self
        prepend_before(:each) do
          group_class.onceler.replay_into!(self)
        end
      end

      def onceler!
        extend AmbitiousHelpers
      end
    end
  end
end
