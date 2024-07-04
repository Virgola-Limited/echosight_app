class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  if Rails.env.test?
    skip_before_action :verify_authenticity_token
  end

  helper_method :current_or_guest_user

  # Use Devise's authentication filter for staging environment
  before_action :authenticate_admin_user!, if: :staging_environment?
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :track_twitter_ad_click

  protected

  def after_sign_in_path_for(resource)
    dashboard_index_path
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end

  private

  def track_twitter_ad_click
    if params[:utm_source] == 'twitter' && params[:utm_campaign] == 'ad_campaign'
      ahoy.track "Twitter Ad Click", { campaign: params[:utm_campaign], campaign_id: params[:twclid] }
      cookies[:ad_campaign] = {
        value: params[:utm_campaign],
      }
      cookies[:campaign_id] = {
        value: params[:twclid],
      }
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
