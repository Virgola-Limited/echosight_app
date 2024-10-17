# app/controllers/admin_users/sessions_controller.rb
module AdminUsers
  class SessionsController < Devise::SessionsController
    layout 'active_admin_logged_out'
    helper ::ActiveAdmin::ViewHelpers
  end
end