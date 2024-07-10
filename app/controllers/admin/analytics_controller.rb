# app/controllers/admin/analytics_controller.rb
module Admin
  class AnalyticsController < ApplicationController
    before_action :authenticate_admin_user!

    def dashboard
      @campaign_sign_ups = User.where.not(ad_campaign_id: nil).group("DATE(created_at)", :ad_campaign_id).count

      @categories = @campaign_sign_ups.keys.map { |(date, _)| date }.uniq.sort
      @series_data = @campaign_sign_ups.group_by { |(_, campaign)| campaign }.map do |campaign, data|
        {
          name: campaign.to_s || "Unknown Campaign", # Ensure name is a string
          data: @categories.map { |date| data.find { |(d, _), _| d == date }&.last || 0 }
        }
      end
    end
  end
end
