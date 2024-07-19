# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    def create
      super do |resource|
        if resource.persisted?
          campaign_id = cookies[:ad_campaign]
          if campaign_id.present?
            ad_campaign = AdCampaign.find_by(campaign_id: campaign_id)
            if ad_campaign
              ahoy.track "Sign Up", user_id: resource.id, campaign_id: ad_campaign.campaign_id, utm_source: ad_campaign.utm_source
              resource.update(ad_campaign: ad_campaign)

              # Send Slack notification
              message = "New registration: Email: #{resource.email}, Campaign ID: #{ad_campaign.campaign_id}"
              Notifications::SlackNotifier.call(message: message, channel: :general)
            end
          end
        end
      end
    end

    def after_inactive_sign_up_path_for(_resource)
      flash.delete(:notice)
      single_message_index_path(message_type: :after_sign_up)
    end

    def destroy
      raise 'You cannot delete your account'
    end

    protected

    def update_resource(resource, params)
      resource.update_with_password(params)
    end
  end
end
