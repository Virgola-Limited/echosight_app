# app/controllers/two_factor_authentications_controller.rb
class TwoFactorAuthenticationsController < AuthenticatedController
  before_action :authenticate_user!

  def show
    @qr_code = current_user.otp_qr_code.as_svg(module_size: 4)
  end

  def enable
    if current_user.validate_and_consume_otp!(params[:otp_code])
      current_user.update(otp_required_for_login: true)
      redirect_to two_factor_authentication_path, notice: 'Two-Factor Authentication enabled successfully.'
    else
      flash.now[:alert] = 'Invalid OTP code. Please try again.'
      @qr_code = current_user.otp_qr_code.as_svg(module_size: 4)
      render :show
    end
  end

  def disable
    current_user.update(otp_required_for_login: false)
    redirect_to two_factor_authentication_path, notice: 'Two-Factor Authentication disabled successfully.'
  end
end
