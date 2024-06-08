class PostsTableComponent < ViewComponent::Base
  include ApplicationHelper
  include LinkHelper

  def initialize(posts:, max_posts: 10)
    @posts = posts.first(max_posts)
  end

  private

  attr_reader :posts

end
