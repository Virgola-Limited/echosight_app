class VotesController < ApplicationController
  def create
    votable = params[:votable_type].constantize.find(params[:votable_id])
    votable.votes.create(user: current_user)
    redirect_back(fallback_location: root_path)
  end
end
