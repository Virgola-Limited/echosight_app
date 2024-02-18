ActiveAdmin.register Tweet do
  actions :index

  # Preload tweet_metrics association
  includes :identity, :tweet_metrics

  scope :with_latest_metrics, default: true do |tweets|
    tweets.joins("LEFT JOIN (
                    SELECT tweet_id, MAX(pulled_at) as latest_pulled_at
                    FROM tweet_metrics
                    GROUP BY tweet_id
                  ) latest_metrics ON tweets.id = latest_metrics.tweet_id")
          .joins("LEFT JOIN tweet_metrics ON tweet_metrics.tweet_id = tweets.id AND tweet_metrics.pulled_at = latest_metrics.latest_pulled_at")
  end

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
        column "Impression Count", sortable: 'tweet_metrics.impression_count' do |tweet|
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

  controller do
    def scoped_collection
      super.includes :tweet_metrics
    end
  end
end
