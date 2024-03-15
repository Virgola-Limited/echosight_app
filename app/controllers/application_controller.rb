class ApplicationController < ActionController::Base
  helper_method :current_or_guest_user

  # Use Devise's authentication filter for staging environment
  before_action :authenticate_admin_user!, if: :staging_environment?

  private

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
