class PostsController < AuthenticatedController
  include Pagy::Backend

  def index
    tweet_metrics_query = Twitter::TweetMetricsQuery.new(identity: current_user.identity, date_range: 'all')
    results = tweet_metrics_query.all_tweets_for_user

    Rails.logger.debug("paul Results class: #{results.class.name}")

    # Simplify for debugging
    @pagy, @posts = pagy(results)
    Rails.logger.debug("paul Pagination: #{@pagy.inspect}")
    Rails.logger.debug("paul Posts count after pagination: #{@posts.count}")
  end
end
