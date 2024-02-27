class ApplicationController < ActionController::Base
  helper_method :current_or_guest_user
  before_action :authenticate_staging

  private

  def authenticate_staging
    # return unless Rails.env.staging?

    # authenticate_or_request_with_http_basic do |username, password|
    #   username == ENV['SITE_USERNAME'] && password == ENV['SITE_PASSWORD']
    # end
  end

  def current_or_guest_user
    if user_signed_in?
      current_user
    else
      NullUser.new
    end
  end
end
