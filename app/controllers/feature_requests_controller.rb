class FeatureRequestsController < AuthenticatedController
  before_action :authenticate_user! # Ensure the user is logged in

  def index
    load_feature_requests
    @new_feature_request = FeatureRequest.new
    set_flash_message
  end

  def create
    load_feature_requests
    @new_feature_request = current_user.feature_requests.build(feature_request_params)
    if @new_feature_request.save
      redirect_to feature_requests_path, notice: 'Feature request added successfully.'
    else
      render :index
    end
  end

  private

  private

  def set_flash_message
    link = view_context.link_to('Dashboard', dashboard_index_path).html_safe
    unless current_user.syncable?
      flash.now[:notice] = "Check your #{link} for the steps to enable your public page.".html_safe
    end
  end

  def load_feature_requests
    @feature_requests = FeatureRequest.left_joins(:votes)
                                      .group(:id)
                                      .order('COUNT(votes.id) DESC')
  end

  def feature_request_params
    params.require(:feature_request).permit(:title, :description)
  end
end
