# app/queries/tweet_counts_query.rb
class TweetCountsQuery
  attr_reader :user

  def initialize(user)
    @user = user
    @memoized_counts = {}
  end

  def this_weeks_tweets_count
    tweets_count(start_time: 1.week.ago)
  end

  def last_weeks_tweet_count
    tweets_count(start_time: 2.weeks.ago, end_time: 1.week.ago)
  end

  def calculate_tweets_change
    this_weeks_tweets_count - last_weeks_tweet_count
  end

  def tweets_count(start_time:, end_time: nil)
    # Generate a unique key for memoization based on start_time and end_time
    memo_key = [start_time.to_i, end_time&.to_i].join("-")
    return @memoized_counts[memo_key] if @memoized_counts[memo_key]

    endpoint = 'tweets/search/recent'
    params = {
      'query' => "from:#{user.twitter_handle}",
      'start_time' => start_time.utc.iso8601,
      'tweet.fields' => 'created_at'
    }

    # Construct the full endpoint with query parameters
    full_endpoint = "#{endpoint}?#{URI.encode_www_form(params)}"

    response = x_client.get(full_endpoint)
    count = parse_tweet_count(response)

    # Memoize the count
    @memoized_counts[memo_key] = count
  end

  private

  def parse_tweet_count(response)
    if response.is_a?(Net::HTTPSuccess)
      tweet_data = JSON.parse(response.body)
      tweet_data['meta']['result_count']
    else
      Rails.logger.error("Error fetching tweets: #{response.body}")
      0
    end
  end

  def x_client
    @x_client ||= TwitterClientService.new(user).client
  end
end
