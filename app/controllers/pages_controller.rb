# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def landing
    unless current_or_guest_user.guest?
      redirect_to dashboard_index_path
    end
  end
end
