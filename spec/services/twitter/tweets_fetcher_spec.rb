# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Twitter::TweetsFetcher do
  let!(:identity) { create(:identity, :with_oauth_credential, :loftwah) }
  let(:user) { identity.user }
  let(:vcr_response_time) { Time.parse('Tue, 05 Mar 2024 18:54:26 GMT') }
  let(:oldest_expected_date) { vcr_response_time - 7.days }
  let(:subject) { described_class.new(user:) }
  let(:expected_tweets) { 630 }

  before do
    allow(UserUpdater).to receive(:new).with(any_args).and_return(double(call: nil))
  end

  it 'does not create duplicate TweetMetric records for the same tweet on the same day' do
    VCR.use_cassette('Twitter__TweetsFetcher_fetches_and_saves_tweets_and_tweet_metrics_for_the_last_seven_days') do
      expect { subject.call }.to change { TweetMetric.count }.from(0).to(630)
    end

    expect(TweetMetric.count).to be_positive # Ensure metrics were created

    VCR.use_cassette('Twitter__TweetsFetcher_fetches_and_saves_tweets_and_tweet_metrics_for_the_last_seven_days') do
      expect { subject.call }.not_to(change { TweetMetric.count })
    end

    user.tweets.each do |tweet|
      expect(tweet.tweet_metrics.count).to eq(1) # Ensuring only one metric per tweet
    end
  end

  it 'fetches and saves tweets and tweet metrics for the last seven days' do
    VCR.use_cassette('Twitter__TweetsFetcher_fetches_and_saves_tweets_and_tweet_metrics_for_the_last_seven_days') do
      expect(TweetMetric.count).to eq(0)
      expect { subject.call }.to change { user.tweets.count }.by(expected_tweets)
      expect(TweetMetric.count).to eq(expected_tweets)
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

  let(:expected_user_data) do
    {
      'id' => '1192091185',
      'username' => 'loftwah',
      'name' => 'Loftwah',
      'public_metrics' => {
        'followers_count' => 6676,
        'following_count' => 4554,
        'listed_count' => 42,
        'tweet_count' => 52_729
      },
      'description' => "Revolutionize Your Social Media Strategy with Echosight | https://t.co/wMI0LubEYS | https://t.co/HLB3aL1R1I | https://t.co/IbbT2ndwo1 | https://t.co/i9vT0Nnmo4",
      'image_url' => 'https://pbs.twimg.com/profile_images/1756873036220059648/zc13kjbX_normal.jpg',
      'banner_url' => 'https://pbs.twimg.com/profile_banners/1192091185/1707817030'
    }
  end

  it 'send todays user data to UserMetricsUpdater' do
    VCR.use_cassette('Twitter__TweetsFetcher_fetches_and_saves_tweets_and_tweet_metrics_for_the_last_seven_days') do
      subject.call
    end
  end

  it 'sends todays user data to UserUpdater' do
    VCR.use_cassette('Twitter__TweetsFetcher_fetches_and_saves_tweets_and_tweet_metrics_for_the_last_seven_days') do
      expect(UserUpdater).to receive(:new).with(expected_user_data)
      subject.call
    end
  end
end
