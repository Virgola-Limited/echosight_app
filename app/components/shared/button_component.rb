module Shared
  class ButtonComponent < ViewComponent::Base
    def initialize(text:, url:)
      @text = text
      @url = url
    end
  end
end