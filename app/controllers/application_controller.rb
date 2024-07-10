class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  if Rails.env.test?
    skip_before_action :verify_authenticity_token
  end

  helper_method :current_or_guest_user

  # Use Devise's authentication filter for staging environment
  before_action :authenticate_admin_user!, if: :staging_environment?
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :track_ad_campaign_click

  protected

  def after_sign_in_path_for(resource)
    dashboard_index_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end

  private

  def track_ad_campaign_click
    if params[:campaign_id].present?
      ad_campaign = AdCampaign.find_by(campaign_id: params[:campaign_id])
      if ad_campaign
        ahoy.track "Ad Campaign Click", { campaign_id: ad_campaign.campaign_id, utm_source: ad_campaign.utm_source }
        cookies[:ad_campaign] = {
          value: ad_campaign.campaign_id,
          expires: 1.hour.from_now
        }
        cookies[:utm_source] = {
          value: ad_campaign.utm_source,
          expires: 1.hour.from_now
        }
      else
        error_details = {
          campaign_id: params[:campaign_id],
          params: params.to_unsafe_h
        }
        ExceptionNotifier.notify_exception(
          StandardError.new("AdCampaign not found"),
          data: error_details
        )
      end
    end
  end

  # Check if the current environment is staging
  def staging_environment?
    Rails.env.staging?
  end

  def current_or_guest_user
    if user_signed_in?
      current_user
    else
      NullUser.new
    end
  end

end
