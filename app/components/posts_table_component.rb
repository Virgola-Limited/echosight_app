class PostsTableComponent < ApplicationComponent
  include LinkHelper

  def initialize(posts:)
    @posts = posts
  end

  private

  attr_reader :posts

  def sortable(column, title = nil)
    title ||= column.titleize
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
    link_to title, { sort: "#{column} #{direction}" }, class: "sort-link"
  end

  def sort_column
    params[:sort].present? ? params[:sort].split.first : 'created_at'
  end

  def sort_direction
    params[:sort].present? && params[:sort].split.last == 'desc' ? 'desc' : 'asc'
  end
end
