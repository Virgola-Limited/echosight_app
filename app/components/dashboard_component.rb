class DashboardComponent < ApplicationComponent
  def initialize(current_user:)
    @current_user = current_user
  end

  def show_steps_to_complete_message?
    show_connect_to_twitter_message? || show_subscription_message?
  end

  def show_connect_to_twitter_message?
    !current_user.twitter_connection_valid?
  end

  def show_subscription_message?
    !current_user.active_subscription?
  end

  def show_waiting_message?
    current_user.twitter_connection_valid? && !current_user.enough_data_for_public_page? && current_user.active_subscription?
  end

  def show_happy_message?
    current_user.twitter_connection_valid? && current_user.enough_data_for_public_page? && current_user.active_subscription?
  end

  def eligible_for_trial?
    current_user.eligible_for_trial?
  end

  def show_2fa_reminder?
    !current_user.otp_required_for_login
  end

  private

  attr_reader :current_user
end
