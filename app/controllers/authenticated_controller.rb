class AuthenticatedController < ApplicationController
  before_action :authenticate_user!

  def authenticate_user!
    unless user_signed_in?
      if flash[:notice]
        flash[:notice] = flash[:notice]
      else
        flash[:notice] = 'You must be signed in to access this page.'
      end
      redirect_to new_user_registration_url
    end
  end
end