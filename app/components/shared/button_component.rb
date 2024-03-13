module Shared
  class ButtonComponent < ViewComponent::Base
    def initialize(text:, url:)
      @text = text
      Rails.logger.debug('paul' + url.inspect)
      @url = url
    end
  end
end