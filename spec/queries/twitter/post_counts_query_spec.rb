require 'rails_helper'

RSpec.describe Twitter::PostCountsQuery do
  let(:identity) { create(:identity, :random_credentials) }
  let(:user) { create(:user, identity: identity) }

  def expected_results_formatted(recent_count:, difference_count:, days_of_data_in_difference_count:, days_of_data_in_recent_count:)
    {
      recent_count: recent_count,
      difference_count: difference_count,
      days_of_data_in_recent_count: days_of_data_in_recent_count,
      days_of_data_in_difference_count: days_of_data_in_difference_count
    }
  end

  describe '#days_of_data_in_recent_count' do
    (1..15).each do |days|
      context "when there are #{days} days of tweets" do
        before do
          days.times do |i|
            create(:tweet, identity: identity, twitter_created_at: DateTime.now - i.days)
          end
        end

        xit "returns correct data for #{days} days of tweets" do
          query = described_class.new(identity: identity)

          result = query.days_of_data_in_recent_count
          recent_count = result[:recent_count]
          difference_count = result[:difference_count]
          days_of_data_in_recent_count = result[:days_of_data_in_recent_count]
          days_of_data_in_difference_count = result[:days_of_data_in_difference_count]

          expected_recent_count = [days, 7].min # Since the query is set up to look 7 days back
          expected_difference = days >= 14 ? 0 : nil # Expecting 0 difference when there are 14 or more days, since 1 tweet per day
          expected_days_of_data = days

          formatted_expected_results = expected_results_formatted(
            recent_count: expected_recent_count,
            difference_count: expected_difference,
            days_of_data_in_difference_count: expected_days_of_data >= 14 ? 7 : 0, # Expecting 7 days in difference count only if 14 or more days of data
            days_of_data_in_recent_count: expected_recent_count # days_of_data_in_recent_count should match the recent_count as it's the period looked into
          )
          expect(result).to eq(formatted_expected_results)
        end
      end
    end
  end
end
