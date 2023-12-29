module Twitter
class TweetCountsQuery
  attr_reader :user

  def initialize(user)
    @user = user
    @memoized_counts = {}
  end

  def this_weeks_tweets_count
    Rails.logger.debug('paul' + 'this weeks'.inspect)
    tweets = fetch_tweets_from_last_two_weeks
    tweets.count { |tweet| DateTime.parse(tweet['created_at']) >= 1.week.ago }
  end

  def last_weeks_tweet_count
    Rails.logger.debug('paul' + 'last weeks'.inspect)
    tweets = fetch_tweets_from_last_two_weeks
    tweets.count { |tweet| DateTime.parse(tweet['created_at']) >= 2.weeks.ago && DateTime.parse(tweet['created_at']) < 1.week.ago }
  end

  def calculate_tweets_change
    this_weeks_tweets_count - last_weeks_tweet_count
  end

  private

# Fetch tweets from the last two weeks and memoize
def fetch_tweets_from_last_two_weeks
  # doesnt like two weeks ago?
  start_time = 1.weeks.ago
  # memo_key = start_time.to_i.to_s
  # return @memoized_counts[memo_key] if @memoized_counts[memo_key]

  endpoint = 'tweets/search/recent'
  params = {
    'query' => "from:#{user.twitter_handle}",
    'start_time' => start_time.utc.iso8601,
    'tweet.fields' => 'created_at'
  }
  Rails.logger.debug('paul params' + params.inspect)
  full_endpoint = "#{endpoint}?#{URI.encode_www_form(params)}"

  response = x_client.get(full_endpoint)
  # Log the raw response for debugging
  Rails.logger.debug("paul Twitter API response: #{response.inspect}")

  if response.is_a?(Hash) && response.key?('data')
    # @memoized_counts[memo_key] = response['data']
    response.fetch('data', [])
  else
    Rails.logger.error("Unexpected response format or error: #{response}")
    []
  end
end

  def x_client
    @x_client ||= TwitterClientService.new(user).client
  end
end
end
