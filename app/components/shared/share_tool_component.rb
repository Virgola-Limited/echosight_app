module Shared
  class ShareToolComponent < ApplicationComponent
    attr_reader :modal_id, :chart_id, :title

    def initialize(modal_id:, chart_id:, title: nil)
      @modal_id = modal_id
      @chart_id = chart_id
      @title = title || "Share"
    end
  end
end