# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def landing
    return if current_or_guest_user.guest?

    redirect_to dashboard_index_path
  end

  def faq
    # Here you can add any logic if needed for the FAQ page.
  end
end
