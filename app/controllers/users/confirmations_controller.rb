class Users::ConfirmationsController < Devise::ConfirmationsController
  def after_confirmation_path_for(resource_name, resource)
    sign_in(resource)
    flash[:notice] = t('devise.confirmations.confirmed')
    dashboard_index_path
  end
end
