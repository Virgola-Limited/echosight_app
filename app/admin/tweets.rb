ActiveAdmin.register Tweet do
  actions :index

  # Preload tweet_metrics association
  includes :identity, :tweet_metrics

  index do
    column :id
    column "Tweet" do |tweet|
      link_to tweet.text.truncate(50), "https://twitter.com/#{tweet.identity.handle}/status/#{tweet.twitter_id}", target: "_blank"
    end
    column "User Email" do |tweet|
      if tweet.identity&.user
        link_to tweet.identity.user.email, admin_user_path(tweet.identity.user)
      else
        "No User"
      end
    end
    column :created_at
    column :updated_at

    Tweet.reflect_on_all_associations(:has_many).each do |association|
      if association.name == :tweet_metrics
        column :retweet_count do |tweet|
          tweet.tweet_metrics.order(pulled_at: :desc).first&.retweet_count || "N/A"
        end
        column :quote_count do |tweet|
          tweet.tweet_metrics.order(pulled_at: :desc).first&.quote_count || "N/A"
        end
        column :like_count do |tweet|
          tweet.tweet_metrics.order(pulled_at: :desc).first&.like_count || "N/A"
        end
        column :impression_count do |tweet|
          tweet.tweet_metrics.order(pulled_at: :desc).first&.impression_count || "N/A"
        end
        column :reply_count do |tweet|
          tweet.tweet_metrics.order(pulled_at: :desc).first&.reply_count || "N/A"
        end
        column :bookmark_count do |tweet|
          tweet.tweet_metrics.order(pulled_at: :desc).first&.bookmark_count || "N/A"
        end
        column :user_profile_clicks do |tweet|
          tweet.tweet_metrics.order(pulled_at: :desc).first&.user_profile_clicks || "N/A"
        end
        column :pulled_at do |tweet|
          tweet.tweet_metrics.order(pulled_at: :desc).first&.pulled_at || "N/A"
        end

      end
    end

    actions
  end

  # controller do
  #   def columns_for_tweet_metrics(tweet)
  #     # Select the most recent TweetMetric based on `pulled_at`
  #     recent_metric = tweet.tweet_metrics.order(pulled_at: :desc).first

  #     if recent_metric
  #       column :retweet_count do
  #         recent_metric.retweet_count
  #       end
  #       column :quote_count do
  #         recent_metric.quote_count
  #       end
  #       column :like_count do
  #         recent_metric.like_count
  #       end
  #       column :impression_count do
  #         recent_metric.impression_count
  #       end
  #       column :reply_count do
  #         recent_metric.reply_count
  #       end
  #       column :bookmark_count do
  #         recent_metric.bookmark_count
  #       end
  #       column :user_profile_clicks do
  #         recent_metric.user_profile_clicks
  #       end
  #       column :pulled_at do
  #         recent_metric.pulled_at
  #       end
  #     else
  #       # Define columns with "N/A" if no metrics are available
  #       %i[retweet_count quote_count like_count impression_count reply_count bookmark_count user_profile_clicks pulled_at].each do |metric|
  #         column metric do
  #           "N/A"
  #         end
  #       end
  #     end
  #   end
  # end
end
