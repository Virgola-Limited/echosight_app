# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    layout 'authenticated', only: %i[edit update]

    # Redirect to a custom path after a user signs up but isn't confirmed
    def after_inactive_sign_up_path_for(_resource)
      # remove the flash and show a friendly custom message
      flash.delete(:notice)
      single_message_index_path(message_type: :after_sign_up)
    end

    protected

    # Override update_resource method
    def update_resource(resource, params)
      # check this doesnt break with twitter 2
      if resource.identity.nil? || resource.identity.provider != 'twitter'
        resource.update_with_password(params)
      else
        resource.update_without_password(params)
      end
    end
  end
end
