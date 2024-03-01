require 'rails_helper'

RSpec.describe SocialData::ClientAdapter, vcr: { cassette_name: 'SocialData__Client_fetch_user_tweets_fetches_new_tweets_from_the_API.yml' } do
  let(:identity) { create(:identity) }
  let(:user) { identity.user }
  let!(:oauth_credential) { create(:oauth_credential, identity: identity) }
  let(:client_adapter) { described_class.new(user) }

  describe '#fetch_user_tweets' do
    it 'returns adapted social data in the expected format' do
      adapted_data = client_adapter.fetch_user_tweets
      expect(adapted_data).to be_a(Hash)
      expect(adapted_data['data']).to be_an(Array)
      expect(adapted_data['data'].last).to eq(first_tweet)
    end


    let(:first_tweet) {
      {
        "id"=>"1740498992587567374",
        "text"=>"test",
        "created_at"=>"2023-12-28T22:24:31.000000Z",
        "public_metrics" => {"like_count"=>0, "quote_count"=>0, "reply_count"=>0, "retweet_count"=>0}
      }
    }

    # {"tweet_created_at"=>"2024-02-17T22:36:03.000000Z", "id"=>1758983678515085403, "id_str"=>"1758983678515085403", "text"=>nil, "full_text"=>"test", "source"=>"<a href=\"https://mobile.twitter.com\" rel=\"nofollow\">Twitter Web App</a>", "truncated"=>false, "in_reply_to_status_id"=>nil, "in_reply_to_status_id_str"=>nil, "in_reply_to_user_id"=>nil, "in_reply_to_user_id_str"=>nil, "in_reply_to_screen_name"=>nil, "user"=>{"id"=>1691930809756991488, "id_str"=>"1691930809756991488", "name"=>"Topher", "screen_name"=>"TopherToy", "location"=>"", "url"=>nil, "description"=>"Revolutionize Your Twitter/X Strategy with Echosight https://t.co/uZpeIYc5Nq", "protected"=>false, "verified"=>false, "followers_count"=>3, "friends_count"=>16, "listed_count"=>0, "favourites_count"=>11, "statuses_count"=>15, "created_at"=>"2023-08-16T21:52:25.000000Z", "profile_banner_url"=>"https://pbs.twimg.com/profile_banners/1691930809756991488/1702516482", "profile_image_url_https"=>"https://pbs.twimg.com/profile_images/1729697224278552576/pa9ZhTkQ_normal.jpg", "can_dm"=>false}, "quoted_status_id"=>nil, "quoted_status_id_str"=>nil, "is_quote_status"=>false, "quoted_status"=>nil, "retweeted_status"=>nil, "quote_count"=>0, "reply_count"=>0, "retweet_count"=>0, "favorite_count"=>0, "lang"=>"en", "entities"=>{"user_mentions"=>[], "urls"=>[], "hashtags"=>[], "symbols"=>[]}, "views_count"=>14, "bookmark_count"=>0}
  end
end
