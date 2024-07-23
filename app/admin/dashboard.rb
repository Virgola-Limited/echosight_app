ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }
  days_to_fetch = Twitter::NewTweetsFetcher.days_to_fetch

  content title: proc { I18n.t("active_admin.dashboard") } do
    h2 "Tweets with More Than 1 Tweet Metric"
    section do
      tweets_with_multiple_metrics = Tweet.joins(:tweet_metrics)
                                          .where("tweet_metrics.created_at >= ?", 3.days.ago)
                                          .group("tweets.id")
                                          .having("COUNT(tweet_metrics.id) > 1")

      table_for tweets_with_multiple_metrics do
        column :id
        column "Created At", :created_at
        column :text do |tweet|
          truncate(tweet.text, omission: "...", length: 100)
        end
        column "Metrics Count" do |tweet|
          tweet.tweet_metrics.count
        end
        column "User Email" do |tweet|
          if tweet.identity&.user
            tweet.identity.user.email
          end
        end
      end
    end

    h2 "Last 10 Incomplete User Twitter Data Updates in last #{days_to_fetch} days"
    section do
      table_for Twitter::TweetDataChecksQuery.incomplete_user_updates(Twitter::NewTweetsFetcher.days_to_fetch.days.ago) do
        column :id
        column :started_at
        column "Error Message", :error_message do |update|
          span truncate(update.error_message, length: 300), title: update.error_message
        end
        column :sync_class
        column "Identity UID", :identity_id do |update|
          update.identity.uid
        end
        column "User Email", :identity_id do |update|
          update.identity.user.email
        end
        column :completed_at
        column "Actions" do |update|
          link_to "View", admin_user_twitter_data_update_path(update), class: "member_link"
        end
      end
    end

    h2 "Tweets with First Metric Issues"
    section do
      problematic_tweets = Twitter::TweetDataChecksQuery.problematic_tweets

      table_for problematic_tweets.limit(10) do
        column :id
        column "Created At", :created_at
        column "First Metric Time", :first_metric_time
        column :text do |tweet|
          truncate(tweet.text, omission: "...", length: 100)
        end
        column "User Email" do |tweet|
          tweet.identity.user.email
        end
      end
      div do
        span "Total problematic tweets: #{problematic_tweets.count}"
      end
    end

    h2 "Tweets Needing Refresh Summary"
    tweets_data = Twitter::TweetDataChecksQuery.tweets_needing_refresh

    section do
      div do
        span "Total Users with Tweets not updated in 24 hours: #{tweets_data.size}"
      end
      table_for tweets_data.take(10) do
        column "User" do |data|
          data[:user]
        end
        column "Count of Tweets Needing Refresh" do |data|
          data[:count]
        end
      end
    end

    h2 "Aggregated TweetMetrics by Day"
    section do
      aggregated_metrics = Twitter::LeaderboardQuery.new.aggregated_metrics_for_all_identities

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
