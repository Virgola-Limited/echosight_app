
class UpdateTwitterDataJob
  include Sidekiq::Job
  sidekiq_options retry: false

  def perform(user_id: nil)
    if user_id
      user = User.find(user_id)
      fetch_and_log_twitter_data(user)
      return
    end

    confirmed_users.each do |user|
      fetch_and_log_twitter_data(user)
    end
  end

  private

  def fetch_and_log_twitter_data(user)
    data_update_log = UserTwitterDataUpdate.create!(identity_id: user.identity.id, started_at: Time.current)

    begin
      update_user(user)
    rescue StandardError => e
      message = "Failed to complete update user #{user.id} #{user.email}: #{e.message}"
      data_update_log.update(error_message: message)
      raise message
      # No completed_at is set in case of error, indicating the update did not complete successfully.
    else
      data_update_log.update(completed_at: Time.current) # Set completed_at only if no errors occurred.
    end
  end

  # TODO; Consider passing identity
  def update_user(user)
    Twitter::FollowersUpdater.new(user).call
    Twitter::NewTweetsFetcher.new(user).call
    Twitter::TweetMetricsRefresher.new(user).call
  end

  def confirmed_users
    # TODO remove Loftwah from this query
    User.confirmed.joins(:identity).merge(Identity.valid_identity).where(name: 'Loftwah')
  end
end
