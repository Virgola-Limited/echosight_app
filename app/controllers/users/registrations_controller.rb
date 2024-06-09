# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    layout 'authenticated', only: %i[edit update]

    # before_action :prevent_sign_up, only: [:create]

    def update
      self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
      resource_updated = update_resource(resource, account_update_params)
      yield resource if block_given?
      if resource_updated
        if is_flashing_format?
          set_flash_message :notice, update_needs_confirmation?(resource, prev_unconfirmed_email) ?
            :update_needs_confirmation : :updated
        end
        bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?
        respond_with resource, location: after_update_path_for(resource)
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end

    # Redirect to a custom path after a user signs up but isn't confirmed
    def after_inactive_sign_up_path_for(_resource)
      # remove the flash and show a friendly custom message
      flash.delete(:notice)
      single_message_index_path(message_type: :after_sign_up)
    end

    def destroy
      raise 'You cannot delete your account'
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

    private

    def account_update_params
      params.require(:user).permit(:name, :last_name, :email, :password, :password_confirmation, :current_password, :following_on_twitter)
    end

    # def prevent_sign_up
    #   flash.delete(:alert)
    #   # this alert isnt working but most users wont see the page anyway
    #   redirect_to root_path, alert: "We are currently only allowing new users via invitation only. "
    # end
  end
end
