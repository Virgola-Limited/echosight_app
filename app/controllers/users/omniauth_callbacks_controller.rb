module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def twitter2
      auth = request.env['omniauth.auth']

      if user_signed_in?
        # Scenario 1: User is already signed in with Devise
        @user = current_user
        @user.update_identity_from_auth(auth)
        redirect_to dashboard_index_path
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
    end
  end
end
