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
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
    link_to title, { sort: "#{column} #{direction}", query: params[:query] }, class: "sort-link"
  end

  def sort_column
    sort.present? ? sort.split.first : 'created_at'
  end

  def sort_direction
    sort.present? && sort.split.last == 'desc' ? 'desc' : 'asc'
  end
end
