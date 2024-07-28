module Shared
  class AlertComponent < ViewComponent::Base
    ALERT_TYPES = {
      yellow: { text_color: "text-yellow-800", bg_color: "bg-yellow-50", dark_text_color: "yellow-300" },
      green: { text_color: "text-green-800", bg_color: "bg-green-50", dark_text_color: "green-300" },
      red: { text_color: "text-red-800", bg_color: "bg-red-50", dark_text_color: "red-300" }
    }.freeze

    def initialize(message:, alert_type: :yellow)
      @message = message
      @text_color, @bg_color, @dark_text_color = ALERT_TYPES.fetch(alert_type).values_at(:text_color, :bg_color, :dark_text_color)
    end

    private

    attr_reader :message, :text_color, :bg_color, :dark_text_color
  end
end
