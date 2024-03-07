# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Twitter::TweetsFetcher do
  let!(:identity) { create(:identity, :with_oauth_credential, :loftwah) }
  let(:user) { identity.user }
  let(:vcr_response_time) { Time.parse('Tue, 05 Mar 2024 18:54:26 GMT') }
  let(:oldest_expected_date) { vcr_response_time - 7.days }
  let(:subject) { described_class.new(user:) }
  let(:expected_tweets) { 630 }

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
        # byebug
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
      "id"=>"1192091185",
      "username" => "loftwah",
      "name" => "Loftwah",
      "public_metrics" => {
        "followers_count" => 6676,
        "following_count" => 4554,
        "listed_count" => 42,
        "tweet_count" => 52729
      }
    }
  end

  fit 'send todays user data to UserMetricsUpdater' do
    VCR.use_cassette('Twitter__TweetsFetcher_fetches_and_saves_tweets_and_tweet_metrics_for_the_last_seven_days') do
      travel_to Time.parse('Wed, 06 Mar 2024 00:00:00 GMT') do
        expect(Twitter::UserMetricsUpdater).to receive(:new).with(user: expected_user_data).and_call_original
        subject.call
      end
    end
  end
end