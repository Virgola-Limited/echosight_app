class FeatureRequestsController < AuthenticatedController
  before_action :authenticate_user! # Ensure the user is logged in

  def index
    load_feature_requests
    @new_feature_request = FeatureRequest.new
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

  def load_feature_requests
    @feature_requests = FeatureRequest.left_joins(:votes)
                                      .group(:id)
                                      .order('COUNT(votes.id) DESC')
  end

  def feature_request_params
    params.require(:feature_request).permit(:title, :description)
  end
end
