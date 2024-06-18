# app/controllers/users/sessions_controller.rb
class Users::SessionsController < Devise::SessionsController
  def create
    self.resource = warden.authenticate!(auth_options)
    if self.resource.otp_required_for_login
      session[:otp_user_id] = self.resource.id
      redirect_to new_otp_user_session_path
    else
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, self.resource)
      yield self.resource if block_given?
      respond_with self.resource, location: after_sign_in_path_for(self.resource)
    end
  rescue Warden::Errors::AuthenticationError => e
    flash.now[:alert] = I18n.t('devise.failure.invalid')
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    set_minimum_password_length
    respond_with(resource, location: new_session_path(resource_name))
  end

  def new_otp
    @user = User.find(session[:otp_user_id])
    unless @user
      flash[:alert] = I18n.t('devise.failure.invalid')
      redirect_to new_session_path(resource_name)
    end
  end

  def verify_otp
    user = User.find(session[:otp_user_id])
    if user && user.otp_required_for_login && user.validate_and_consume_otp!(params[:user][:otp_attempt])
      flash[:notice] = I18n.t('devise.sessions.signed_in')
      sign_in(user)
      session.delete(:otp_user_id)
      redirect_to after_sign_in_path_for(user)
    else
      flash.now[:alert] = 'Invalid OTP code. Please try again.'
      render :new_otp
    end
  end
end
