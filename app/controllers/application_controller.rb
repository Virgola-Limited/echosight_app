class ApplicationController < ActionController::Base
  helper_method :current_or_guest_user

  def current_or_guest_user
    if user_signed_in?
      current_user
    else
      NullUser.new
    end
  end
end
