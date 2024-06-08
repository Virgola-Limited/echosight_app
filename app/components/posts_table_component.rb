class PostsTableComponent < ViewComponent::Base
  include ApplicationHelper
  include LinkHelper

  def initialize(posts:, rows_to_show: 10)
    @rows_to_show = rows_to_show
    @posts = posts
  end

  private

  attr_reader :posts, :rows_to_show

end
