require 'rails_helper'

RSpec.describe Twitter::TweetAndMetricUpserter do
  let!(:identity) { create(:identity, :with_oauth_credential, :loftwah) }
  let(:user) { identity.user }
  let(:subject) { described_class.new(user: user, tweet_data: tweet_data) }
  let(:tweet_data) {
  {
    "id" => "1765189290131399049",
    "text" => "@drewskadoosh @ziademarcus Are you married to a shinigami?",
    "created_at" => "2024-03-06T01:34:57.000000Z",
    "public_metrics" => {
      "retweet_count" => 1,
      "reply_count" => 2,
      "like_count" => 3,
      "quote_count" => 4,
      "impression_count" => 5,
      "bookmark_count" => nil
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

  let(:subject) { described_class.new(user: user, tweet_data: tweet_data) }

  context 'when there is only one tweet metric for the tweet' do
    context 'and the existing metric was created less than 24 hours from the current time' do
      it 'updates the existing metric' do
        # Set up the initial state: one tweet with one associated tweet metric
        tweet_creation_time = Time.current.beginning_of_day + 13.hours
        travel_to tweet_creation_time do
          tweet = create(:tweet, twitter_id: '1765189290131399049', identity: user.identity, twitter_created_at: DateTime.now) # Check this shouldnt be DateTime.current
          create(:tweet_metric, tweet: tweet,
            retweet_count: 10,
            like_count: 20,
            quote_count: 30,
            impression_count: 40,
            reply_count: 50,
            bookmark_count: 60,
            pulled_at: DateTime.now # Check this shouldnt be DateTime.current
          )
        end

        # Expect that there is initially only one TweetMetric
        expect(TweetMetric.count).to eq(1)

        # Prepare tweet_data with updated metrics to be used by TweetAndMetricUpserter
        updated_tweet_data = tweet_data.merge("public_metrics" => {
          "retweet_count" => 11,
          "reply_count" => 22,
          "like_count" => 33,
          "quote_count" => 44,
          "impression_count" => 55,
          "bookmark_count" => 0  # Assuming a nil bookmark_count should be treated as 0
        })

        upserter = described_class.new(user: user, tweet_data: updated_tweet_data)

        # Travel less than 24 hours into the future and call the upserter
        travel_to tweet_creation_time + 23.hours do
          expect { upserter.call }.not_to change { TweetMetric.count }

          # Fetch the updated metric and verify its attributes have been updated
          updated_metric = Tweet.find_by(twitter_id: '1765189290131399049').tweet_metrics.last

          expect(updated_metric.retweet_count).to eq(11)
          expect(updated_metric.reply_count).to eq(22)
          expect(updated_metric.like_count).to eq(33)
          expect(updated_metric.quote_count).to eq(44)
          expect(updated_metric.impression_count).to eq(55)
          expect(updated_metric.bookmark_count).to eq(0)  # Ensure nil is treated as 0
        end
      end
    end

    context 'and the existing metric was created more than 24 hours from the current time' do
      it 'creates a new metric for the current time' do
        # Set up the initial state: one tweet with one associated tweet metric older than 24 hours
        tweet_creation_time = Time.current.beginning_of_day
        tweet = create(:tweet, twitter_id: '1765189290131399049', identity: user.identity, twitter_created_at: tweet_creation_time)

        travel_to tweet_creation_time do
          create(:tweet_metric, tweet: tweet,
            retweet_count: 10,
            like_count: 20,
            quote_count: 30,
            impression_count: 40,
            reply_count: 50,
            bookmark_count: 60,
            pulled_at: tweet_creation_time
          )
        end

        # Expect that there is initially only one TweetMetric
        expect(TweetMetric.count).to eq(1)

        # Prepare tweet_data with new metrics to be used by TweetAndMetricUpserter
        new_tweet_data = tweet_data.merge("public_metrics" => {
          "retweet_count" => 1,
          "reply_count" => 2,
          "like_count" => 3,
          "quote_count" => 4,
          "impression_count" => 5,
          "bookmark_count" => nil  # Assuming a nil bookmark_count should be treated as 0
        })

        upserter = described_class.new(user: user, tweet_data: new_tweet_data)

        # Travel more than 24 hours into the future and call the upserter
        travel_to tweet_creation_time + 25.hours do
          expect { upserter.call }.to change { TweetMetric.count }.by(1)

          # Fetch the new metric and verify its attributes
          new_metric = Tweet.find_by(twitter_id: '1765189290131399049').tweet_metrics.order(created_at: :desc).first

          expect(new_metric.retweet_count).to eq(1)
          expect(new_metric.reply_count).to eq(2)
          expect(new_metric.like_count).to eq(3)
          expect(new_metric.quote_count).to eq(4)
          expect(new_metric.impression_count).to eq(5)
          expect(new_metric.bookmark_count).to eq(0)  # Ensure nil is treated as 0
          expect(new_metric.pulled_at).to be_within(1.minute).of(DateTime.current)
        end
      end
    end
  end

  context 'when multiple tweet metrics exist for the tweet' do
    context 'and the last metric was created on the same day as the current time' do
      it 'updates the last metric' do
        # Set up the initial state: one tweet with multiple associated tweet metrics, where the last one is from the same day
        early_morning = Time.current.beginning_of_day + 2.hours
        travel_to early_morning do
          tweet = create(:tweet, twitter_id: '1765189290131399049', identity: user.identity, twitter_created_at: DateTime.now)
          # Check this shouldnt be DateTime.current
          create(:tweet_metric, tweet: tweet, pulled_at: early_morning - 1.day) # Earlier metric from the previous day
          create(:tweet_metric, tweet: tweet, pulled_at: early_morning) # Last metric from the same day
        end

        # Expect that there are initially two TweetMetric records
        expect(TweetMetric.count).to eq(2)

        # Prepare tweet_data with updated metrics for the existing tweet
        updated_tweet_data = tweet_data.merge("public_metrics" => {
          "retweet_count" => 11,
          "reply_count" => 22,
          "like_count" => 33,
          "quote_count" => 44,
          "impression_count" => 55,
          "bookmark_count" => nil  # Assuming a nil bookmark_count should be treated as 0
        })

        upserter = described_class.new(user: user, tweet_data: updated_tweet_data)

        # Travel to a later time on the same day and call the upserter
        later_today = early_morning + 10.hours
        travel_to later_today do
          expect { upserter.call }.not_to change { TweetMetric.count }

          # Fetch the updated metric (which should be the last one) and verify its attributes have been updated
          updated_metric = Tweet.find_by(twitter_id: '1765189290131399049').tweet_metrics.order(pulled_at: :desc).first

          expect(updated_metric.retweet_count).to eq(11)
          expect(updated_metric.reply_count).to eq(22)
          expect(updated_metric.like_count).to eq(33)
          expect(updated_metric.quote_count).to eq(44)
          expect(updated_metric.impression_count).to eq(55)
          expect(updated_metric.bookmark_count).to eq(0)  # Ensure nil is treated as 0
          expect(updated_metric.pulled_at.to_date).to eq(later_today.to_date)  # Ensure the metric is still from the same day
        end
      end
    end

    context 'when multiple tweet metrics exist for the tweet' do
      context 'and the last metric was created on a different day than the current time' do
        it 'creates a new metric for the current day' do
          # Set up the initial state: one tweet with multiple associated tweet metrics, where the last one is from a previous day
          yesterday = Time.current.beginning_of_day - 2.hours
          travel_to yesterday do
            tweet = create(:tweet, twitter_id: '1765189290131399049', identity: user.identity, twitter_created_at: DateTime.now)
            # Check this shouldnt be DateTime.current
            create(:tweet_metric, tweet: tweet, pulled_at: yesterday - 1.day) # An earlier metric from two days ago
            create(:tweet_metric, tweet: tweet, pulled_at: yesterday) # Last metric from yesterday
          end

          # Expect that there are initially two TweetMetric records
          expect(TweetMetric.count).to eq(2)

          # Prepare tweet_data with new metrics to be used by TweetAndMetricUpserter
          new_tweet_data = tweet_data.merge("public_metrics" => {
            "retweet_count" => 12,
            "reply_count" => 23,
            "like_count" => 34,
            "quote_count" => 45,
            "impression_count" => 56,
            "bookmark_count" => nil  # Assuming a nil bookmark_count should be treated as 0
          })

          upserter = described_class.new(user: user, tweet_data: new_tweet_data)

          # Travel to the current day, after the last metric was created, and call the upserter
          travel_to Time.current.beginning_of_day + 10.hours do
            expect { upserter.call }.to change { TweetMetric.count }.by(1)

            # Fetch the newly created metric and verify its attributes
            new_metric = Tweet.find_by(twitter_id: '1765189290131399049').tweet_metrics.order(created_at: :desc).first

            expect(new_metric.retweet_count).to eq(12)
            expect(new_metric.reply_count).to eq(23)
            expect(new_metric.like_count).to eq(34)
            expect(new_metric.quote_count).to eq(45)
            expect(new_metric.impression_count).to eq(56)
            expect(new_metric.bookmark_count).to eq(0)  # Ensure nil is treated as 0
            expect(new_metric.pulled_at.to_date).to eq(Time.current.to_date)  # Ensure the new metric is for the current day
          end
        end
      end
    end
  end
end