ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }
  days_to_fetch = Twitter::NewTweetsFetcher.days_to_fetch

  content title: proc { I18n.t("active_admin.dashboard") } do
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
          update.identity.uid # Assuming `uid` is a column in your `identities` table
        end
        column "User Email", :identity_id do |update|
          update.identity.user.email # Adjust according to your user association
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
          tweet.identity.user.email  # Adjust according to your user association
        end
      end
      div do
        span "Total problematic tweets: #{problematic_tweets.count}"
      end
    end

    h2 "Tweets Needing Refresh"
    tweets = Twitter::TweetDataChecksQuery.tweets_needing_refresh

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

    h2 "Users with No Recent Twitter User Metrics"
    section do
      users = Twitter::TweetDataChecksQuery.users_with_no_recent_twitter_user_metrics

      table_for users do
        column :id
        column :email
        column :recent_metric_date
      end
    end

    h2 "Aggregated TweetMetrics by Day"
    section do
      # Define a scope or method in your TweetMetric model that performs the aggregation
      aggregated_metrics = Twitter::TweetDataChecksQuery.aggregated_metrics

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
