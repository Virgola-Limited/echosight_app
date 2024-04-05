require 'rails_helper'

RSpec.describe Twitter::TweetAndMetricUpserter do
  let!(:identity) { create(:identity, :with_oauth_credential, :loftwah) }
  let(:user) { identity.user }
  let(:vcr_response_time) { Time.parse('Tue, 05 Mar 2024 18:54:26 GMT') }
  let(:subject) { described_class.new(user: user, tweet_data: tweet_data) }
  let(:oldest_expected_date) { vcr_response_time - 7.days }
  let(:tweet_data) {
    {
      "id" => "1765189290131399049",
      "text" => "@drewskadoosh @ziademarcus Are you married to a shinigami?",
      "created_at" => "2024-03-06T01:34:57.000000Z",
      "public_metrics" => {
        "retweet_count" => 0,
        "reply_count" => 1,
        "like_count" => 1,
        "quote_count" => 0,
        "impression_count" => nil,
        "bookmark_count" => 0
      },
      "is_pinned" => "false",
      "user" => {
        "data" => {
          "id" => "1192091185",
          "name" => "Loftwah",
          "username" => "loftwah",
          "public_metrics" => {
            "followers_count" => 6676,
            "following_count" => 4554,
            "listed_count" => 42,
            "tweet_count" => 52729
          },
          "description" => "Revolutionize Your Social Media Strategy with Echosight | https://t.co/wMI0LubEYS | https://t.co/HLB3aL1R1I | https://t.co/IbbT2ndwo1 | https://t.co/i9vT0Nnmo4",
          "image_url" => "https://pbs.twimg.com/profile_images/1756873036220059648/zc13kjbX_normal.jpg",
          "banner_url" => "https://pbs.twimg.com/profile_banners/1192091185/1707817030"
        }
      }
    }
  }

  before do
    allow(IdentityUpdater).to receive(:new).with(any_args).and_return(double(call: nil))
  end

  fit 'does not create duplicate TweetMetric records for the same tweet on the same day' do
    twelve_noon = Time.current.beginning_of_day + 12.hours
    travel_to twelve_noon do

      VCR.use_cassette('Twitter__TweetsFetcher_call') do
        expect { subject.call }.to change { TweetMetric.count }.by(1)
      end
    end

    one_oclock = Time.current.beginning_of_day + 13.hours
    travel_to one_oclock do
      VCR.use_cassette('Twitter__TweetsFetcher_call') do
        expect { subject.call }.not_to(change { TweetMetric.count })
      end

      user.tweets.each do |tweet|
        expect(tweet.tweet_metrics.count).to eq(1)
      end
    end
  end

  it 'fetches and saves tweets and tweet metrics for the last seven days' do
    VCR.use_cassette('Twitter__TweetsFetcher_call') do
      expect(TweetMetric.count).to eq(0)
      expect { subject.call }.to change { user.tweets.count }.by(1)
      expect(TweetMetric.count).to eq(1)
      user.tweets.each do |tweet|
        expect(tweet.tweet_metrics.count).to eq(1)
        expect(tweet.twitter_created_at).to be >= oldest_expected_date
      end

      oldest_tweet = Tweet.order(twitter_created_at: :asc).first
      # this might fail with other data sets
      expect(oldest_tweet.twitter_created_at).to be_within(1.day).of(oldest_expected_date)
      TweetMetric.last.tap do |metric|
        expect(metric.impression_count).to eq(35)
        expect(metric.like_count).to eq(4)
        expect(metric.quote_count).to eq(1)
        expect(metric.reply_count).to eq(2)
        expect(metric.retweet_count).to eq(3)
        expect(metric.bookmark_count).to eq(0)
        # consider adding favorite_count
      end
    end
  end
end