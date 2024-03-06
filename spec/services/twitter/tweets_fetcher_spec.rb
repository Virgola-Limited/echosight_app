# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Twitter::TweetsFetcher, :vcr do
  let!(:identity) { create(:identity, :with_oauth_credential, :loftwah) }
  let(:user) { identity.user }
  let(:vcr_response_time) { Time.parse("Tue, 05 Mar 2024 18:54:26 GMT")}
  let(:oldest_expected_date) { vcr_response_time - 7.days }
  let(:subject) { described_class.new(user:) }
  let(:exepected_tweets) { 630 }

  it 'fetches and saves tweets and tweet metrics for the last seven days' do
    expect(TweetMetric.count).to eq(0)
    expect { subject.call }. to change { user.tweets.count }.by(exepected_tweets)
    expect(TweetMetric.count).to eq(exepected_tweets)
    user.tweets.each do |tweet|
      expect(tweet.tweet_metrics.count).to eq(1)
      expect(tweet.twitter_created_at).to be >= oldest_expected_date
    end

    oldest_tweet = Tweet.order(twitter_created_at: :asc).first
    # this might fail with other data sets
    expect(oldest_tweet.twitter_created_at).to be_within(1.day).of(oldest_expected_date)
  end

  it 'saves followers data for today' do
    VCR.use_cassette('Twitter__TweetsFetcher_fetches_and_saves_tweets_and_tweet_metrics_for_the_last_seven_days') do
      subject.call
    end
  end
end