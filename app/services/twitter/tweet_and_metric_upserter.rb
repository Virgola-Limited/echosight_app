module Twitter
  class TweetAndMetricUpserter < Services::Base
    attr_reader :tweet_data, :identity, :api_batch_id, :allow_update

    def initialize(tweet_data:, identity:, api_batch_id:, allow_update: true)
      @tweet_data = tweet_data
      @identity = identity
      @api_batch_id = api_batch_id
      @allow_update = allow_update
    end

    def call
      tweet = initialize_or_update_tweet
      if tweet
        tweet_metric = find_or_initialize_tweet_metric(tweet)

        result = update_tweet_metric(tweet_metric)
        {
          tweet_id: tweet.id,
          success: result.saved_changes?,
          tweet_metric: result,
          identity: @identity,
          tweet_data: tweet_data,
        }
      end
      {
        success: false,
        api_batch_id: api_batch_id,
        tweet_data: tweet_data,
      }
    end

    private

    def initialize_or_update_tweet
      tweet = Tweet.find_or_initialize_by(id: tweet_data['id'])
      if tweet.new_record?
        tweet.assign_attributes(tweet_attributes.merge(api_batch_id: @api_batch_id))
      else
        # TODO: this is probably causing issues when we get a 500 on the tweet updater as the tweet could be in another batch
        if allow_update
          tweet.assign_attributes(tweet_attributes)
        end
      end

      tweet.save! if tweet.changed?
      tweet
    end


    def tweet_attributes
      {
        text: tweet_data['text'],
        identity_id: identity.id,
        twitter_created_at: DateTime.parse(tweet_data['created_at'])
      }
    end

    def find_or_initialize_tweet_metric(tweet)
      last_metric = tweet.tweet_metrics.order(pulled_at: :desc).first

      if last_metric.nil? || last_metric.updated_count >= 3
        tweet.tweet_metrics.build
      else
        last_metric
      end
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
