class UserSettingsController < AuthenticatedController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    if params[:user_settings].present?
      params[:user_settings].each do |key, value|
        current_user.update_setting(key, value)
      end
      redirect_to edit_user_settings_path, notice: 'Settings updated successfully.'
    else
      redirect_to edit_user_settings_path, alert: 'No settings provided.'
    end
  end
end
