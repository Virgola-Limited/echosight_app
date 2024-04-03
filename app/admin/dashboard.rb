ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }
  days_to_fetch = Twitter::TweetsFetcher.days_to_fetch

  content title: proc { I18n.t("active_admin.dashboard") } do
    h2 "Incomplete User Twitter Data Updates"
    section do
      table_for UserTwitterDataUpdate.joins(identity: :user).where(completed_at: nil).where('user_twitter_data_updates.created_at > ?', days_to_fetch.days.ago).order('user_twitter_data_updates.started_at DESC').limit(10) do
        column :started_at
        column "Error Message", :error_message do |update|
          span truncate(update.error_message, length: 300), title: update.error_message
        end
        column "Identity UID", :identity_id do |update|
          update.identity.uid # Assuming `uid` is a column in your `identities` table
        end
        column "User Email", :identity_id do |update|
          update.identity.user.email # Adjust according to your user association
        end
      end
    end

    h2 "Tweets Needing Refresh"
    tweets = Tweet.where('updated_at < ?', 24.hours.ago)
                  .where('twitter_created_at > ?', days_to_fetch.days.ago)
    section do
      div do
        span "Total Tweets not updated in 24 hours: #{tweets.count}"
      end
      table_for tweets.limit(10) do
        column :twitter_id
        column :created_at
        column :text do |tweet|
          truncate(tweet.text, omision: "...", length: 100)
        end
        column :updated_at
        column :user do |tweet|
          tweet.identity.user.email  # Adjust according to your user association
        end
      end
    end

    h2 "Users Missing Recent Twitter Metrics"
    section do
      users_missing_metrics = User.joins(:identity)  # Ensure users have an identity
                              .where.not(identities: {id: TwitterUserMetric.where('created_at > ?', 24.hours.ago).select(:identity_id)})

      table_for users_missing_metrics do
        column :email
        column "Last Metric Date" do |user|
          user.identity.twitter_user_metrics.order(created_at: :desc).first&.created_at
        end
      end
    end

    h2 "Aggregated TweetMetrics by Day"
    section do
      # Define a scope or method in your TweetMetric model that performs the aggregation
      aggregated_metrics = TweetMetric.joins(tweet: { identity: :user })
                                      .select("date(tweet_metrics.pulled_at) as day, users.id as user_id, count(*) as count")
                                      .group("day, users.id")
                                      .order("day DESC")

      table_for aggregated_metrics do
        column :day
        column "User" do |metric|
          user = User.find(metric.user_id)
          link_to user.email, admin_user_path(user)
        end
        column :count
      end
    end

  end
end
