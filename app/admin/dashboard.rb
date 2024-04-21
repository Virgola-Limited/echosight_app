ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }
  days_to_fetch = Twitter::NewTweetsFetcher.days_to_fetch

  content title: proc { I18n.t("active_admin.dashboard") } do
    h2 "Last 10 Incomplete User Twitter Data Updates in last #{days_to_fetch} days"
    section do
      table_for UserTwitterDataUpdate.joins(identity: :user).where(completed_at: nil).where('user_twitter_data_updates.created_at > ?', days_to_fetch.days.ago).order('user_twitter_data_updates.started_at DESC').limit(10) do
        column :started_at
        column "Error Message", :error_message do |update|
          span truncate(update.error_message, length: 300), title: update.error_message
        end
        column :sync_class
        column "Identity UID", :identity_id do |update|
          update.identity.uid # Assuming `uid` is a column in your `identities` table
        end
        column "User Email", :identity_id do |update|
          update.identity.user.email # Adjust according to your user association
        end
        column :completed_at
      end
    end

    h2 "Tweets with First Metric Issues"
    section do
      earliest_metrics_subquery = TweetMetric.select('MIN(id) AS id')
      .where('created_at < ?', 26.hours.ago)
      .group(:tweet_id)

      # Main query to fetch tweets with their earliest metric info, filtering those not having updated_count of 1
      problematic_tweets = Tweet.joins(:tweet_metrics)
      .where('tweet_metrics.id IN (?)', earliest_metrics_subquery)
      .where(tweet_metrics: { updated_count: [nil, 0] })

      table_for problematic_tweets.limit(10) do
        column :id
        column "Created At", :created_at
        column "First Metric Time", :first_metric_time
        column :text do |tweet|
          truncate(tweet.text, omission: "...", length: 100)
        end
        column "User Email" do |tweet|
          tweet.identity.user.email  # Adjust according to your user association
        end
      end
      div do
        span "Total problematic tweets: #{problematic_tweets.count}"
      end
    end

    h2 "Tweets Needing Refresh"
    recent_metric_tweet_ids = TweetMetric.joins(tweet: { identity: :user })
    .where('tweet_metrics.updated_at >= ?', 24.hours.ago)
    .merge(User.syncable)
    .select('tweet_metrics.tweet_id')

    # Fetch tweets either missing metrics entirely or not in the list of recent metrics, and ensure they're from syncable users
    tweets = Tweet.joins(identity: :user)
    .merge(User.syncable)
    .where('tweets.twitter_created_at > ?', days_to_fetch.days.ago)
    .where.not(id: recent_metric_tweet_ids)

    section do
      div do
        span "Total Tweets not updated in 24 hours: #{tweets.count}"
      end
      table_for tweets.limit(10) do
        column :id
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
