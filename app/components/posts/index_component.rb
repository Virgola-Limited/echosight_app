class Posts::IndexComponent < ApplicationComponent
  include Pagy::Backend

  attr_reader :current_user, :query, :sort, :pagy_instance, :paginated_posts

  def initialize(current_user:, query:, sort:)
    @current_user = current_user
    @query = query
    @sort = sort
  end

  def alert_message
    if !current_user.active_subscription? && query.present?
      render(Shared::AlertComponent.new(
        message: "Search posts doesn't work on the example posts.",
        alert_type: :yellow
      ))
    elsif current_user.active_subscription? && paginated_posts.empty?
      render(Shared::AlertComponent.new(
        message: "We haven't synced any posts yet. Check back later.",
        alert_type: :yellow
      ))
    end
  end

  def posts_and_pagination
    if current_user.active_subscription?
      results = fetch_posts
      pagy_instance, paginated_results = pagy(results)
      [pagy_instance, paginated_results]
    else
      [nil, demo_data.top_posts]
    end
  end

  def render_pagination
    render(PaginationComponent.new(pagy: pagy_instance)) if pagy_instance
  end

  private

  def fetch_posts
    tweets = current_user.tweets
                         .joins(:tweet_metrics)
                         .select('tweets.*, tweet_metrics.*, ((COALESCE(tweet_metrics.retweet_count, 0) + COALESCE(tweet_metrics.quote_count, 0) + COALESCE(tweet_metrics.like_count, 0) + COALESCE(tweet_metrics.reply_count, 0)) * 100.0 / NULLIF(tweet_metrics.impression_count, 0)) AS engagement_rate_percentage')

    if query.present?
      search_query = query.split.map { |word| "#{word}:*" }.join(' & ')
      tsquery = ActiveRecord::Base.sanitize_sql_array(["to_tsquery('english', ?)", search_query])
      tweets = tweets.where("searchable @@ #{tsquery}")
                     .order(Arel.sql("ts_rank(searchable, #{tsquery}) DESC"))
    end

    if sort.present?
      column, direction = sort.split
      column_name = sort_column(column)
      tweets = tweets.order(Arel.sql("#{column_name} #{direction}")) if column_name
    end

    # byebug
    tweets
  end

  def sort_column(column)
    case column
    when 'tweet'
      'tweets.text'
    when 'impression_count'
      'tweet_metrics.impression_count'
    when 'retweet_count'
      'tweet_metrics.retweet_count'
    when 'quote_count'
      'tweet_metrics.quote_count'
    when 'like_count'
      'tweet_metrics.like_count'
    when 'reply_count'
      'tweet_metrics.reply_count'
    when 'engagement_rate_percentage'
      'engagement_rate_percentage'
    else
      'tweets.created_at'
    end
  end

  def demo_data
    @demo_data ||= DemoPublicPageService.new.call
  end

  def before_render
    @pagy_instance, @paginated_posts = posts_and_pagination
  end
end
