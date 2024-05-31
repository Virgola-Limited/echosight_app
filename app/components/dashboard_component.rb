class DashboardComponent < ApplicationComponent
  def initialize(current_user:)
    @current_user = current_user
  end

  def show_steps_to_complete_message?
    show_connect_to_twitter_message? || show_subscription_message?
  end

  def show_connect_to_twitter_message?
    !current_user.connected_to_twitter?
  end

  def show_subscription_message?
    !current_user.active_subscription?
  end

  def show_waiting_message?
    current_user.connected_to_twitter? && !current_user.enough_data_for_public_page? && current_user.active_subscription?
  end

  def show_happy_message?
    current_user.connected_to_twitter? && current_user.enough_data_for_public_page? && current_user.active_subscription?
  end

  def eligible_for_trial?
    current_user.accepted_invitation? && ENV.fetch('TRIAL_PERIOD_DAYS', 0).to_i.positive?
  end

  private

  attr_reader :current_user
end
