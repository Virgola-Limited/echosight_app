module Twitter
  class ImpressionsQuery
    attr_reader :user, :tweet_id

    def initialize(user, tweet_id)
      @user = user
      @tweet_id = tweet_id
    end

    def fetch_impressions
      twitter_client = ClientService.new(user).client
      endpoint = "2/tweets/#{tweet_id}"
      params = { 'tweet.fields' => 'non_public_metrics' }
      response = twitter_client.get(endpoint, params)
      parse_impressions(response)
    end

    private

    def parse_impressions(response)
      if response.success? && response.body['data'] && response.body['data']['non_public_metrics']
        response.body['data']['non_public_metrics']['impression_count']
      else
        Rails.logger.error("Failed to retrieve impressions: #{response.status} - #{response.body}")
        nil
      end
    end
  end
end
