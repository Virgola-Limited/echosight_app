class PostsTableComponent < ApplicationComponent
  include LinkHelper

  def initialize(posts:, sortable: false, sort: nil)
    @posts = posts
    @sortable = sortable
    @sort = sort
  end

  def sortable_header(column, title)
    return title unless @sortable

    current_column, direction = parse_sort(@sort)
    Rails.logger.debug('paul current_column' + current_column.inspect)
    is_current = current_column == column
    new_direction = is_current && direction == 'asc' ? 'desc' : 'asc'

    link_content = tag.span(title, class: "mr-1")
    link_content += sort_icon(column)

    link_to(link_content, { sort: "#{column} #{new_direction}" }, class: header_class(is_current))
  end

  def sort_icon(column)
    return "" unless @sortable

    current_column, direction = parse_sort(@sort)
    is_current = current_column == column

    icon = if !is_current
             default_icon
           elsif direction == 'asc'
             ascending_icon
           else
             descending_icon
           end

    color_class = is_current ? 'text-blue-600 dark:text-blue-400' : 'text-gray-500 dark:text-gray-400'

    tag.span(icon.html_safe, class: color_class)
  end

  private

  attr_reader :posts, :sortable, :sort

  def parse_sort(sort_string)
    return [nil, 'asc'] if sort_string.blank?

    parts = sort_string.to_s.split
    if parts.size == 1
      [parts[0], 'asc']
    else
      direction = parts.last.downcase
      column = parts[0...-1].join('_')
      Rails.logger.debug('paul' + column.inspect)
      [column, ['asc', 'desc'].include?(direction) ? direction : 'asc']
    end
  end

  def header_class(is_current)
    base_class = "font-medium flex items-center justify-center"
    is_current ? "#{base_class} text-blue-600 dark:text-blue-400" : "#{base_class} text-gray-900 dark:text-white hover:text-blue-600 dark:hover:text-blue-400"
  end

  def default_icon
    '<svg class="w-3 h-3 ms-1.5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 24 24">
      <path d="M8.574 11.024h6.852a2.075 2.075 0 0 0 1.847-1.086 1.9 1.9 0 0 0-.11-1.986L13.736 2.9a2.122 2.122 0 0 0-3.472 0L6.837 7.952a1.9 1.9 0 0 0-.11 1.986 2.074 2.074 0 0 0 1.847 1.086Zm6.852 1.952H8.574a2.072 2.072 0 0 0-1.847 1.087 1.9 1.9 0 0 0 .11 1.985l3.426 5.05a2.123 2.123 0 0 0 3.472 0l3.427-5.05a1.9 1.9 0 0 0 .11-1.985 2.074 2.074 0 0 0-1.846-1.087Z"/>
    </svg>'
  end

  def ascending_icon
    '<svg class="w-3 h-3 ms-1.5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 24 24">
      <path d="M8.574 11.024h6.852a2.075 2.075 0 0 0 1.847-1.086 1.9 1.9 0 0 0-.11-1.986L13.736 2.9a2.122 2.122 0 0 0-3.472 0L6.837 7.952a1.9 1.9 0 0 0-.11 1.986 2.074 2.074 0 0 0 1.847 1.086Z"/>
    </svg>'
  end

  def descending_icon
    '<svg class="w-3 h-3 ms-1.5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 24 24">
      <path d="M15.426 12.976H8.574a2.072 2.072 0 0 0-1.847 1.087 1.9 1.9 0 0 0 .11 1.985l3.426 5.05a2.123 2.123 0 0 0 3.472 0l3.427-5.05a1.9 1.9 0 0 0 .11-1.985 2.074 2.074 0 0 0-1.846-1.087Z"/>
    </svg>'
  end

  def sort_column
    parse_sort(sort)[0] || 'created_at'
  end

  def sort_direction
    parse_sort(sort)[1] || 'asc'
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