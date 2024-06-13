module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def twitter2
      auth = request.env['omniauth.auth']

      user = current_user.create_or_update_identity_from_omniauth(auth)

      if user.identity.persisted?
        flash[:notice] = 'Your Twitter/X account has been successfully connected.'
      else
        flash[:alert] = 'There was an error connecting your Twitter/X account. Please try again.'
      end
      redirect_to dashboard_index_path

    rescue ActiveRecord::RecordInvalid => e
      if e.message == 'Identity belongs to a different user'
        redirect_to dashboard_index_path, alert: "This Twitter/X account is already connected to an existing Echosight account. Please log in with that account or contact support using our widget for assistance."
      else
        raise e # Re-raise the exception if it's not related to UID or Handle uniqueness
      end
    end
  end
end