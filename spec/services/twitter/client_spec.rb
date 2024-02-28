require 'rails_helper'

RSpec.describe Twitter::Client do
  let(:identity) { create(:identity) }
  let(:user) { identity.user }
  let!(:oauth_credential) { create(:oauth_credential, identity: identity) }
  let(:client) { described_class.new(user) }

  describe '#fetch_new_tweets' do
    it 'fetches new tweets from the API', :vcr do
      tweets = client.fetch_new_tweets
      p tweets
    end
  end
end
