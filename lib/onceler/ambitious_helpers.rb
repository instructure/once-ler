module Onceler
  module AmbitiousHelpers
    # make :once the default behavior for before/let/etc.
    def once_scope?(scope)
      super || scope.nil?
    end
  end
end
