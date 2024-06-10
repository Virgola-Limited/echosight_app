class VotesController < AuthenticatedController

  def create
    votable = find_votable
    vote = votable.votes.find_or_initialize_by(user: current_user)

    if vote.new_record?
      vote.save
      votes_count = votable.votes.count
      render json: { success: true, votes_count: votes_count }
    else
      render json: { success: false, error: 'You have already voted' }, status: :unprocessable_entity
    end
  end

  private

  def find_votable
    params[:votable_type].constantize.find(params[:votable_id])
  end
end
