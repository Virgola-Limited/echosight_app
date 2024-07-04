# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    layout 'authenticated', only: %i[edit update]

    def create
      super do |resource|
        if resource.persisted?
          campaign_data = { user_id: resource.id }
          campaign_data[:campaign] = cookies[:ad_campaign] if cookies[:ad_campaign]
          campaign_data[:campaign_id] = cookies[:campaign_id] if cookies[:campaign_id]
          ahoy.track "Sign Up", campaign_data

          resource.update(ad_campaign: cookies[:ad_campaign], campaign_id: cookies[:campaign_id])
        end
      end
    end

    # before_action :prevent_sign_up, only: [:create]

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
      # # check this doesnt break with twitter 2
      # for sign up with twitter which we dont use
      # if resource.identity.nil? || resource.identity.provider != 'twitter'
        resource.update_with_password(params)
      # else
        # resource.update_without_password(params)
      # end
    end

    # private

    # def prevent_sign_up
    #   flash.delete(:alert)
    #   # this alert isnt working but most users wont see the page anyway
    #   redirect_to root_path, alert: "We are currently only allowing new users via invitation only. "
    # end
  end
end
