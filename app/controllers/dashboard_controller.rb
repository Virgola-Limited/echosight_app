class DashboardController < AuthenticatedController

  def index
    authenticate_user!

    render(DashboardComponent.new(current_user: current_user))
  end
end
