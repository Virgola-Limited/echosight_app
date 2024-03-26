module Shared
  class HeadingComponent <  ApplicationComponent
    def initialize(text:, heading_type:)
      @text = text
      @heading_type = heading_type
    end
  end
end