class FeatureRequestsController < AuthenticatedController
  def index
    load_feature_requests
    @new_feature_request = FeatureRequest.new
  end

  def create
    load_feature_requests
    @feature_request = FeatureRequest.new(feature_request_params)
    if @feature_request.save
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
    params.require(:feature_request).permit(:title)
  end
end
