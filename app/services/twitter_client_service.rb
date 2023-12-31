class TwitterClientService
  attr_reader :user

  def initialize(user = nil)
    @user = user
  end

  def client(version: :v2)
    X::Client.new(**credentials(version))
  end

  private

  def credentials(version)
    if user
      user_context_credentials(version)
    else
      application_context_credentials(version)
    end
  end

  def user_context_credentials(version)
    base_url = version == :v1_1 ? "https://api.twitter.com/1.1/" : "https://api.twitter.com/2/"
    {
      api_key: ENV['TWITTER_CONSUMER_API_KEY'],
      api_key_secret: ENV['TWITTER_CONSUMER_API_SECRET'],
      access_token: user.identity.token,
      access_token_secret: user.identity.secret,
      base_url: base_url
    }
  end

  def application_context_credentials(version)
    base_url = version == :v1_1 ? "https://api.twitter.com/1.1/" : "https://api.twitter.com/2/"
    {
      bearer_token: ENV['TWITTER_BEARER_TOKEN'],
      base_url: base_url
    }
  end
end
