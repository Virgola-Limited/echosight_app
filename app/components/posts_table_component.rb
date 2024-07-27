class PostsTableComponent < ViewComponent::Base
  include ApplicationHelper
  include LinkHelper

  def initialize(posts:, rows_to_show: 100)
    @rows_to_show = rows_to_show
    @posts = posts
  end

  private

  attr_reader :posts, :rows_to_show

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
