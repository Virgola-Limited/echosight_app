# app/controllers/user_settings_controller.rb
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
      respond_to do |format|
        format.json { render json: { message: 'Settings updated successfully.' }, status: :ok }
        format.html { redirect_to edit_user_settings_path, notice: 'Settings updated successfully.' }
      end
    else
      respond_to do |format|
        format.json { render json: { message: 'No settings provided.' }, status: :unprocessable_entity }
        format.html { redirect_to edit_user_settings_path, alert: 'No settings provided.' }
      end
    end
  end
end
