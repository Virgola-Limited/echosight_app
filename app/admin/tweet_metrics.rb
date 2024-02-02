ActiveAdmin.register TweetMetric do
  actions :index, :show  # Makes the resource read-only

  filter :tweet_identity_user_id, as: :select, collection: -> { User.all.map { |u| [u.email, u.id] } }

  index do
    column "Tweet" do |tweet_metric|
      link_to tweet_metric.tweet.text.truncate(50), "https://twitter.com/#{tweet_metric.tweet.identity.handle}/status/#{tweet_metric.tweet.twitter_id}", target: "_blank"
    end
    column :retweet_count
    column :quotes_count
    column :like_count
    column :quote_count
    column :impression_count
    column :reply_count
    column :bookmark_count
    column :pulled_at
    column :created_at
    column :updated_at
    column :user_profile_clicks
    actions
  end

  show do |tweet_metric|
    attributes_table do
      row "Tweet" do
        link_to tweet_metric.tweet.text, "https://twitter.com/#{tweet_metric.tweet.identity.handle}/status/#{tweet_metric.tweet.twitter_id}", target: "_blank"
      end
      row :retweet_count
      row :quotes_count
      row :like_count
      row :quote_count
      row :impression_count
      row :reply_count
      row :bookmark_count
      row :pulled_at
      row :created_at
      row :updated_at
      row :user_profile_clicks
    end
  end
end
