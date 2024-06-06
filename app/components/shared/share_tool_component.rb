module Shared
  class ShareToolComponent < ViewComponent::Base
    attr_reader :modal_id, :chart_id

    def initialize(modal_id:, chart_id:)
      @modal_id = modal_id
      @chart_id = chart_id
    end
  end
end