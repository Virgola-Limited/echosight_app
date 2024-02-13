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

    h2 "Tweets Needing Metrics Refresh"
    section do
      div do
        # Define recent_metrics_subquery here to ensure it's in scope
        recent_metrics_subquery = TweetMetric.where('created_at >= ?', 24.hours.ago).select(:tweet_id)
        tweets_without_recent_metrics_count = Tweet.where.not(id: recent_metrics_subquery).count
        span "Total Tweets without Metrics updated in the last 24 hours: #{tweets_without_recent_metrics_count}"
      end
      div do
        # If you need to use recent_metrics_subquery again, ensure it's defined again in this scope
        recent_metrics_subquery = TweetMetric.where('created_at >= ?', 24.hours.ago).select(:tweet_id)
        table_for Tweet.includes(:identity).where.not(id: recent_metrics_subquery).order('tweets.created_at ASC').limit(10) do
          column "Tweet ID", :twitter_id
          column "User Email" do |tweet|
            tweet.identity.user.email  # Adjust according to your user association
          end
          column :created_at
          # Other columns as needed
        end
      end
    end
  end
end
