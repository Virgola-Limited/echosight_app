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
    tweets = current_user.tweets.includes(:tweet_metrics)
    tweets = apply_search(tweets) if query.present?
    apply_sorting(tweets)
  end

  def apply_search(tweets)
    search_query = query.split.map { |word| "#{word}:*" }.join(' & ')
    tsquery = ActiveRecord::Base.sanitize_sql_array(["to_tsquery('english', ?)", search_query])
    tweets.where("searchable @@ #{tsquery}")
          .order(Arel.sql("ts_rank(searchable, #{tsquery}) DESC"))
  end

  def apply_sorting(tweets)
    return tweets.order(created_at: :desc) unless sort.present?

    column, direction = sort.split
    case column
    when 'impression_count', 'retweet_count', 'quote_count', 'like_count', 'reply_count', 'bookmark_count', 'engagement_rate'
      tweets.joins(:tweet_metrics)
            .order("tweet_metrics.#{column} #{direction}")
    when 'text'
      tweets.order("LOWER(text) #{direction}")
    else
      tweets.order(column => direction)
    end
  end

  def demo_data
    @demo_data ||= DemoPublicPageService.new.call
  end

  def before_render
    @pagy_instance, @paginated_posts = posts_and_pagination
  end
end
