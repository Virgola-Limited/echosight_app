module Twitter
  class RefreshOauthCredentialsJob
    include Sidekiq::Job

    def perform
      OauthCredential.where('expires_at < ?', Time.current + 1.hour).find_each do |oauth_credential|
        Oauth.new(nil).refresh_token(oauth_credential)
      end
    end
  end
end
