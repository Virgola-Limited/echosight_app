class TwitterClientService
  attr_reader :user

  def initialize(user = nil)
    @user = user
  end

  def client
    X::Client.new(**credentials)
  end

  private

  def credentials
    if user
      user_context_credentials
    else
      application_context_credentials
    end
  end

  def user_context_credentials
    {
      api_key: ENV['TWITTER_CONSUMER_API_KEY'],
      api_key_secret: ENV['TWITTER_CONSUMER_API_SECRET'],
      access_token: user.identity.token,
      access_token_secret: user.identity.secret
    }
  end

  def application_context_credentials
    {
      bearer_token: ENV['TWITTER_BEARER_TOKEN']
    }
  end
end
