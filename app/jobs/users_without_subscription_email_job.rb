class UsersWithoutSubscriptionEmailJob
  include Sidekiq::Job
  sidekiq_options retry: false

  def perform
    one_week_ago = 1.week.ago

    User.joins('LEFT JOIN sent_emails ON sent_emails.user_id = users.id AND sent_emails.email_type = \'users_without_subscription_email\'')
        .where('users.created_at < ?', one_week_ago)
        .where.not(id: Subscription.select(:user_id))
        .where('sent_emails.id IS NULL')
        .find_each do |user|
      UserMailer.users_without_subscription_email(user).deliver_now
    end
  end
end
