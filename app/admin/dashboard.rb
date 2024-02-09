ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    h2 "Incomplete User Twitter Data Updates"
    section do
      table_for UserTwitterDataUpdate.joins(identity: :user).where(completed_at: nil).order('started_at DESC').limit(10) do
        column :started_at
        column "Error Message", :error_message
        column "Identity UID", :identity_id do |update|
          update.identity.uid # Assuming `uid` is a column in your `identities` table
        end
        column "User Email", :identity_id do |update|
          update.identity.user.email # Adjust according to your user association
        end
      end
    end

    h2 "Tweets Needing Refresh"
    section do
      div do
        span "Total Tweets not updated in 24 hours: #{Tweet.where('updated_at < ?', 24.hours.ago).count}"
      end
      table_for Tweet.where('updated_at < ?', 24.hours.ago).order('updated_at ASC').limit(10) do
        column :twitter_id
        column :text do |tweet|
          truncate(tweet.text, omision: "...", length: 100)
        end
        column :updated_at
        column :user do |tweet|
          tweet.identity.user.email  # Adjust according to your user association
        end
      end
    end

    h2 "Tweet Metrics Needing Refresh"
    section do
      div do
        span "Total Tweet Metrics not updated in 24 hours: #{TweetMetric.joins(:tweet).where('tweet_metrics.updated_at < ?', 24.hours.ago).count}"
      end
      table_for TweetMetric.joins(:tweet).where('tweet_metrics.updated_at < ?', 24.hours.ago).order('tweet_metrics.updated_at ASC').limit(10) do
        column "Tweet ID", :tweet_id do |metric|
          metric.tweet.twitter_id
        end
        column :retweet_count
        column :like_count
        column :updated_at
        column "User Email", :tweet_id do |metric|
          metric.tweet.identity.user.email  # Adjust according to your user association
        end
      end
    end
  end # content


end
