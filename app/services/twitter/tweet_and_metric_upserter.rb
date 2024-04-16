module Twitter
  class TweetAndMetricUpserter < Services::Base
    attr_reader :tweet_data, :user

    def initialize(tweet_data:, user: nil)
      @tweet_data = tweet_data
      assign_user(user)

    end

    def call
      tweet = initialize_or_update_tweet
      tweet_metric = find_or_initialize_tweet_metric(tweet)

      # raise "Metric has been updated too many times within 24 hours" if tweet_metric.updated_count >= 2

      update_tweet_metric(tweet_metric)
      {
        tweet: tweet,
        tweet_metric: tweet_metric,
        user: @user
      }
    end

    private

    def assign_user(user)
      @user = user
      return if user

      raise ActiveRecord::RecordNotFound unless @user
    end

    def initialize_or_update_tweet
      tweet = Tweet.find_or_initialize_by(id: tweet_data['id'])
      tweet.assign_attributes(tweet_attributes)
      tweet.save! if tweet.new_record? || tweet.changed?
      tweet
    end

    def tweet_attributes
      {
        text: tweet_data['text'],
        identity_id: user.identity.id,
        twitter_created_at: DateTime.parse(tweet_data['created_at'])
      }
    end

    def find_or_initialize_tweet_metric(tweet)
      last_metric = tweet.tweet_metrics.order(pulled_at: :desc).first
      if last_metric.nil? || (last_metric.pulled_at.to_date != DateTime.current.to_date && tweet.tweet_metrics.count > 1)
        return tweet.tweet_metrics.build
      end
      time_difference_in_hours = (DateTime.current.to_time - last_metric.pulled_at.to_time) / 1.hour
      if time_difference_in_hours < 24
        return last_metric
      else
        return tweet.tweet_metrics.build if last_metric.pulled_at.to_date != DateTime.current.to_date
      end

      last_metric
    end

    def update_tweet_metric(tweet_metric)
      metrics = tweet_data['public_metrics']
      tweet_metric.assign_attributes({
        retweet_count: metrics['retweet_count'].to_i,
        reply_count: metrics['reply_count'].to_i,
        like_count: metrics['like_count'].to_i,
        quote_count: metrics['quote_count'].to_i,
        impression_count: metrics['impression_count'].to_i,
        bookmark_count: metrics['bookmark_count'].to_i,
        pulled_at: DateTime.current,
        updated_count: tweet_metric.updated_count + 1
      })
      tweet_metric.save!
      tweet_metric
    end
  end
end
