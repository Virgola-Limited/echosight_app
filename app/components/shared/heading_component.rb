module Shared
  class HeadingComponent < ViewComponent::Base
    def initialize(text:, heading_type:)
      @text = text
      @heading_type = heading_type
    end
  end
end