module Twitter
  class SearchTweetUpserter < Services::Base
    attr_reader :tweet_data, :search, :api_batch_id

    def initialize(tweet_data:, search:, api_batch_id:)
      @tweet_data = tweet_data
      @search = search
      @api_batch_id = api_batch_id
    end

    def call
      tweet = initialize_or_update_tweet

      if tweet
        associate_tweet_with_search(tweet)
      end

      {
        tweet_id: tweet.id,
        success: tweet.saved_changes?,
        tweet_data: tweet_data,
      }
    end

    private

    def initialize_or_update_tweet
      tweet = Tweet.find_or_initialize_by(id: tweet_data['id'])
      if tweet.new_record?
        tweet.assign_attributes(tweet_attributes.merge(api_batch_id: @api_batch_id))
        tweet.save!
      end
      tweet
    end

    def associate_tweet_with_search(tweet)
      # Associate the tweet with the search if not already associated
      tweet.searches << search unless tweet.searches.include?(search)
    end

    def tweet_attributes
      {
        text: tweet_data['text'],
        twitter_created_at: DateTime.parse(tweet_data['created_at'])
      }
    end
  end
end
