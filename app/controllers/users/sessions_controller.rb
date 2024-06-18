# app/controllers/users/sessions_controller.rb
class Users::SessionsController < Devise::SessionsController
  def create
    user = User.find_by(email: params[:user][:email])
    if user && user.valid_password?(params[:user][:password])
      if user.access_locked?
        flash.now[:alert] = I18n.t('devise.failure.locked')
        self.resource = resource_class.new(sign_in_params)
        render :new and return
      end

      if user.otp_required_for_login
        session[:otp_user_id] = user.id
        redirect_to new_otp_user_session_path and return
      else
        set_flash_message!(:notice, :signed_in)
        sign_in_and_redirect(user)
      end
    else
      handle_failed_attempt(user)
    end
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

  private

  def handle_failed_attempt(user)
    if user
      user.increment!(:failed_attempts)
      if user.failed_attempts >= Devise.maximum_attempts
        user.lock_access!
        flash.now[:alert] = I18n.t('devise.failure.locked')
      else
        flash.now[:alert] = I18n.t('devise.failure.invalid')
      end
    else
      flash.now[:alert] = I18n.t('devise.failure.invalid')
    end

    self.resource = resource_class.new(sign_in_params)
    render :new
  end
end
