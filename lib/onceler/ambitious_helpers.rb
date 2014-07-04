module Onceler
  module AmbitiousHelpers
    # make :once the default behavior for before/let/etc.
    def once_scopes
      [:once, nil]
    end
  end
end
