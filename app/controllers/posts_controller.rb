class PostsController < AuthenticatedController
  def index
    unless current_user.active_subscription?
      flash.now[:alert] = "To see your posts you need a valid subscription. For now, we've shown you some example posts to see how it would work."
    end
    render Posts::IndexComponent.new(current_user: current_user, query: params[:query], sort: params[:sort])
  end
end