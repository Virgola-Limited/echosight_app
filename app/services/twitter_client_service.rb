# frozen_string_literal: true

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

  #  not sure this is working. will leave comments in until
  def user_context_credentials(version)
    raise 'Not working'
    version == :v1_1 ? 'https://api.twitter.com/1.1/' : 'https://api.twitter.com/2/'
    {
      # api_key: ENV['TWITTER_CONSUMER_API_KEY'],
      # api_key_secret: ENV['TWITTER_CONSUMER_API_SECRET'],
      # bearer_token: user.identity.bearer_token
      # base_url: base_url
    }
  end

  def application_context_credentials(version)
    base_url = version == :v1_1 ? 'https://api.twitter.com/1.1/' : 'https://api.twitter.com/2/'
    {
      bearer_token: ENV['TWITTER_BEARER_TOKEN'],
      base_url:
    }
  end
end
