require 'rails_helper'

RSpec.describe Twitter::TwitterUserMetricsQuery do
  describe '#followers_count' do
    let(:identity) { create(:identity) }

    xit 'validates followers count over a range of days' do
      # Create metrics for each day, and test for each addition


      query = Twitter::TwitterUserMetricsQuery.new(identity:)

      # Validate results based on the period definitions
      expected_results = {
        0 => false, 1 => false, 2 => 5, 3 => 5, 4 => 10, 5 => 10, 6 => 15, 7 => 15, 8 => 20, 9 => 20,
        10 => 25, 11 => 25, 12 => 30, 13 => 30, 14 => 35, 15 => 35
      }

      (0..15).each do |day|
        create(:twitter_user_metric, identity: identity, created_at: Date.current - day.days, date: Date.current - day.days, followers_count: 100 - day * 5)
        expected_change = expected_results[day]

        query = Twitter::TwitterUserMetricsQuery.new(identity:)
        actual_change = query.followers_count
        if expected_change.is_a?(Numeric)
          expect(actual_change).to eq(expected_change), "Failed on day #{day} with expected change #{expected_change} but got #{actual_change}"
        else
          expect(actual_change).to eq(expected_change), "Expected false but got #{actual_change} on day #{day}"
        end
      end
    end
  end
end
