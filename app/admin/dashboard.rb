ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    h2 "Incomplete User Twitter Data Updates"
    section do
      table_for UserTwitterDataUpdate.joins(identity: :user).where(completed_at: nil).where('user_twitter_data_updates.created_at > ?', 7.days.ago).order('user_twitter_data_updates.started_at DESC').limit(10) do
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
                  .where('twitter_created_at > ?', 28.days.ago)
    section do
      div do
        span "Total Tweets not updated in 24 hours: #{tweets.count}"
      end
      table_for tweets.limit(10) do
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
  end
end
