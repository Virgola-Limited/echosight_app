require 'spec_helper'
require_relative '../../../app/services/social_data/client'

RSpec.describe SocialData::Client do
  let(:user) { double('User', identity: double('Identity', uid: '1691930809756991488')) }
  let(:client) { described_class.new(user) }

  describe '#fetch_new_tweets' do
    it 'fetches new tweets from the API', :vcr do
      tweets = client.fetch_new_tweets
      p tweets
    end
  end
end
