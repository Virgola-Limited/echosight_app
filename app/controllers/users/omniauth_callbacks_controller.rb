module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def twitter2
      auth = request.env['omniauth.auth']

      if user_signed_in?
        # Scenario 1: User is already signed in with Devise
        @user = current_user
        @user.update_identity_from_auth(auth)
        redirect_to dashboard_index_path, notice: 'Your Twitter/X account has been successfully connected.'
      else
        # Scenario 2: User is signing up for the first time with Twitter
        @user = User.create_or_update_identity_from_omniauth(auth)

        if @user.persisted?
          @user.confirm unless @user.confirmed?
          @user.remember_me = true
          sign_in_and_redirect @user, event: :authentication
          set_flash_message(:notice, :success, kind: 'Twitter') if is_navigational_format?
        else
          session['devise.twitter_data'] = auth.except('extra')
          redirect_to new_user_registration_url
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      if e.record.errors[:uid].include?('has already been taken') || e.record.errors[:handle].include?('has already been taken')
        redirect_to dashboard_index_path, alert: "This Twitter/X account is already connected to an existing Echosight account. Please log in with that account or contact support for assistance."
      else
        raise e # Re-raise the exception if it's not related to UID or Handle uniqueness
      end
    end
  end
end