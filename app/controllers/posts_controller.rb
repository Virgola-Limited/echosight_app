class PostsController < AuthenticatedController
  include Pagy::Backend

  def index
    tweet_metrics_query = Twitter::TweetMetricsQuery.new(identity: current_user.identity, date_range: 'all')
    @pagy, @posts = pagy(tweet_metrics_query.all_tweets_for_user, items: 100)
  end

  private

  def sort_params
    params.fetch(:sort, 'created_at desc')
  end
end
