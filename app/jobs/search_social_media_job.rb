class SearchSocialMediaJob
  include Sidekiq::Job

  sidekiq_options queue: :default

  # Only do this for syncable users when offering as product
  def perform
    Search.find_each do |search|
      next unless search.last_searched_at.nil? || search.last_searched_at <= Time.current - search_interval

      client = SocialData::Client.new(user: search.user)

      if search.twitter?
        tweets = client.search_tweets({ query: search.keywords, since: search.last_searched_at.to_i }, single_request: true)
        handle_tweets(tweets, search)
      elsif search.threads?
        # Implement Threads search logic here
        # threads = client.search_threads({ query: search.keywords, since: search.last_searched_at.to_i }, single_request: true)
        # Handle the threads, e.g., log them or store them in another table
      end

      search.update(last_searched_at: Time.current)
    end
  end

  private

  def handle_tweets(tweets, search)
    tweets.each do |tweet_data|
      Twitter::SearchTweetUpserter.new(
        tweet_data: tweet_data,
        search: search,
        api_batch_id: api_batch_id
      ).call
    end
  end

  def api_batch_id
    # Return the appropriate API batch ID for tracking purposes
    # You may need to create or fetch this based on your application's logic
    ApiBatch.current.id
  end

  def search_interval
    6.hours
  end
end
