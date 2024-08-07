class PostsTableComponent < ApplicationComponent
  include LinkHelper

  def initialize(posts:, sort:)
    @posts = posts
    @sort = sort
  end

  private

  attr_reader :posts, :sort

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "sort-link #{sort_direction}" : "sort-link"
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
    link_to title, { sort: "#{column} #{direction}", query: params[:query] }, class: css_class
  end

  def sort_column
    sort.present? ? sort.split.first : 'created_at'
  end

  def sort_direction
    sort.present? && sort.split.last == 'desc' ? 'desc' : 'asc'
  end
end