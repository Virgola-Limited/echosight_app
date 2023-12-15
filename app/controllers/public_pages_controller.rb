class PublicPagesController < ApplicationController
  def show
    identity = Identity.find_by(twitter_handle: params[:twitter_handle])
    @user = identity.user if identity.present?
    unless @user
      raise ActionController::RoutingError.new('Not Found')
    end
  end
end
