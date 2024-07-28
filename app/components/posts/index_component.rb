# frozen_string_literal: true

class Posts::IndexComponent < ApplicationComponent
  include Pagy::Backend

  attr_reader :current_user, :query, :pagy_instance, :paginated_posts

  def initialize(current_user:, query:)
    @current_user = current_user
    @query = query
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
    if query.present?
      search_query = query.split.map { |word| "#{word}:*" }.join(' & ')
      tsquery = ActiveRecord::Base.sanitize_sql_array(["to_tsquery('english', ?)", search_query])

      current_user.tweets.where("searchable @@ #{tsquery}")
                         .order(Arel.sql("ts_rank(searchable, #{tsquery}) DESC"))
    else
      current_user.tweets
    end
  end

  def demo_data
    @demo_data ||= DemoPublicPageService.new.call
  end

  def before_render
    @pagy_instance, @paginated_posts = posts_and_pagination
  end
end
