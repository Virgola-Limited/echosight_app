class PostsController < AuthenticatedController
  include Pagy::Backend

  def index
    tweet_metrics_query = Twitter::TweetMetricsQuery.new(identity: current_user.identity, date_range: 'all')
    results = tweet_metrics_query.all_tweets_for_user
    @pagy, @posts = pagy(results)
    @posts = @posts.offset(@pagy.offset).limit(@pagy.items)  # Apply pagination to the results
    Rails.logger.debug("Pagination: #{@pagy.inspect}")
    Rails.logger.debug("Posts count: #{@posts.count}")
    Rails.logger.debug("Pagy offset: #{@pagy.offset}, Pagy limit: #{@pagy.items}")
  end

  private

  def sort_params
    params.fetch(:sort, 'created_at desc')
  end
end
