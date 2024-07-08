# app/controllers/admin/analytics_controller.rb
module Admin
  class AnalyticsController < ApplicationController
    before_action :authenticate_admin_user!

    def dashboard
      @campaign_sign_ups = User.where.not(campaign_id: nil).group("DATE(created_at)", :campaign_id).count
      Rails.logger.debug('paul' + @campaign_sign_ups.inspect)
      # Prepare data for the chart component
      @categories = @campaign_sign_ups.keys.map { |(date, _)| date }.uniq.sort
      @series_data = @campaign_sign_ups.group_by { |(_, campaign)| campaign }.map do |campaign, data|
        {
          name: campaign,
          data: @categories.map { |date| data.find { |(d, _), _| d == date }&.last || 0 }
        }
      end
    end
  end
end
