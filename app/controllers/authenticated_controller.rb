class AuthenticatedController < ApplicationController
  before_action :authenticate_user!
  layout 'authenticated'

  def authenticate_user!
    unless user_signed_in?
      flash[:notice] = 'You must be signed in to access this page.'
      redirect_to new_user_registration_url
    end
  end
end