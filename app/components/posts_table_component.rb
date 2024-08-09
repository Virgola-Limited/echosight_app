class PostsTableComponent < ApplicationComponent
  include LinkHelper

  def initialize(posts:, sortable: false, sort: nil)
    @posts = posts
    @sortable = sortable
    @sort = sort
  end

  private

  attr_reader :posts, :sortable, :sort

  def sortable_header(column, title = nil)
    title ||= column.titleize
    if sortable
      css_class = column == sort_column ? "sort-link #{sort_direction}" : "sort-link"
      direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
      link_to title, { sort: "#{column} #{direction}", query: params[:query] }, class: css_class
    else
      title
    end
  end

  def sort_column
    sort.present? ? sort.split.first : 'created_at'
  end

  def sort_direction
    sort.present? && sort.split.last == 'desc' ? 'desc' : 'asc'
  end

  def engagement_rate(tweet)
    tweet_metric = tweet.tweet_metrics.max_by(&:impression_count)
    return 0 if tweet_metric.nil? || tweet_metric.impression_count.to_i.zero?

    total_interactions = tweet_metric.retweet_count.to_i +
                         tweet_metric.like_count.to_i +
                         tweet_metric.quote_count.to_i +
                         tweet_metric.reply_count.to_i +
                         tweet_metric.bookmark_count.to_i

    (total_interactions.to_f / tweet_metric.impression_count.to_f) * 100
  end
end