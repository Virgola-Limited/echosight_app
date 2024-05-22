class EmailSubscriptionsController < AuthenticatedController

  def edit
    @subscription_lists = MAILKICK_SUBSCRIPTION_LISTS
    @user_subscriptions = current_user.mailkick_subscriptions.pluck(:list)
  end

  def update
    subscriptions = params[:subscriptions] || []
    current_subscriptions = current_user.mailkick_subscriptions.pluck(:list)

    # Subscribe to new lists
    (subscriptions - current_subscriptions).each do |list|
      Mailkick::Subscription.create!(subscriber: current_user, list: list)
    end

    # Unsubscribe from removed lists
    (current_subscriptions - subscriptions).each do |list|
      Mailkick::Subscription.where(subscriber: current_user, list: list).destroy_all
    end

    redirect_to edit_email_subscription_path, notice: 'Your email subscriptions have been updated.'
  end
end