class Users::MasqueradesController < Devise::MasqueradesController
  def show
    logger.debug "Current user: #{current_user.inspect}"
    super
  end

  def current_user
    current_admin_user
  end
end
