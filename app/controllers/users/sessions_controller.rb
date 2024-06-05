# app/controllers/users/sessions_controller.rb
class Users::SessionsController < Devise::SessionsController
  def create
    user = User.find_by(email: params[:user][:email])
    if user && user.valid_password?(params[:user][:password])
      if user.otp_required_for_login
        session[:otp_user_id] = user.id
        redirect_to new_otp_user_session_path
      else
        sign_in(user)
        redirect_to after_sign_in_path_for(user)
      end
    else
      flash[:alert] = 'Invalid email or password. Please try again.'
      render :new
    end
  end

  def new_otp
    @user = User.find(session[:otp_user_id])
    unless @user
      flash[:alert] = 'Invalid email or password. Please try again.'
      redirect_to new_session_path(resource_name)
    end
  end

  def verify_otp
    user = User.find(session[:otp_user_id])
    if user && user.otp_required_for_login && user.validate_and_consume_otp!(params[:user][:otp_attempt])
      sign_in(user)
      session.delete(:otp_user_id)
      redirect_to after_sign_in_path_for(user)
    else
      flash[:alert] = 'Invalid OTP code. Please try again.'
      render :new_otp
    end
  end
end
