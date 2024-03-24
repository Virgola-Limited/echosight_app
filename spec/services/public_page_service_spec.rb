# require 'rails_helper'

# RSpec.describe PublicPageService do
#   let(:identity) { create(:identity) }
#   let(:user) { identity.user }
#   let(:current_user) { create(:user) }
#   let(:admin_user) { create(:admin_user) }
#   let(:service) { described_class.new(handle: identity.handle, current_user: current_user, current_admin_user: admin_user) }
#   let(:tweet_metrics_query) { instance_double(Twitter::TweetMetricsQuery) }

#   describe '#store_post_counts' do
#     before do
#       allow(Twitter::TweetMetricsQuery).to receive(:new).with(user: user).and_return(tweet_metrics_query)

#       # Stub the methods and set expectations
#       allow(tweet_metrics_query).to receive(:tweet_count_over_available_time_period).and_return(100)
#       allow(tweet_metrics_query).to receive(:tweets_change_over_available_time_period).and_return(10)
#       allow(tweet_metrics_query).to receive(:tweet_comparison_days).and_return(7)
#     end

#     it 'retrieves post counts and formats changes correctly' do
#       # Expectations to ensure the methods exist and are called
#       expect(tweet_metrics_query).to receive(:tweet_count_over_available_time_period)
#       expect(tweet_metrics_query).to receive(:tweets_change_over_available_time_period)
#       expect(tweet_metrics_query).to receive(:tweet_comparison_days)

#       results = service.send(:store_post_counts) # Using `send` to call a private method

#       # Verify the results are as expected
#       expect(results).to match_array([100, "10 increase", 7])
#     end
#   end

#   describe '#store_impression_counts' do
#     before do
#       allow(Twitter::TweetMetricsQuery).to receive(:new).with(user: user).and_return(tweet_metrics_query)

#       # Stub the methods and set expectations
#       allow(tweet_metrics_query).to receive(:impressions_count).and_return(200)
#       allow(tweet_metrics_query).to receive(:impressions_change_since_last_week).and_return(-5)

#       # Stub and set expectation for the NumberRoundingService if necessary
#       allow(NumberRoundingService).to receive(:call).with(-5).and_return(-5)
#     end

#     it 'retrieves impression counts and formats changes correctly' do
#       # Expectations to ensure the methods exist and are called
#       expect(tweet_metrics_query).to receive(:impressions_count)
#       expect(tweet_metrics_query).to receive(:impressions_change_since_last_week)

#       service.send(:store_impression_counts) # Using `send` to call a private method

#       # Verify the instance variables are set as expected
#       expect(service.instance_variable_get(:@impressions_count)).to eq(200)
#       expect(service.instance_variable_get(:@impressions_change_since_last_week)).to eq("5% decrease")
#       expect(service.instance_variable_get(:@impressions_comparison_days)).to eq(7)
#     end
#   end

#   describe '#store_likes_counts' do

#     before do
#       allow(Twitter::TweetMetricsQuery).to receive(:new).with(user: user).and_return(tweet_metrics_query)

#       # Stub the methods and set expectations
#       allow(tweet_metrics_query).to receive(:likes_count).and_return(300)
#       allow(tweet_metrics_query).to receive(:likes_change_since_last_week).and_return(10)

#       # Stub and set expectation for the NumberRoundingService if necessary
#       allow(NumberRoundingService).to receive(:call).with(10).and_return(10)
#     end

#     it 'retrieves likes counts and formats changes correctly' do
#       # Expectations to ensure the methods exist and are called
#       expect(tweet_metrics_query).to receive(:likes_count)
#       expect(tweet_metrics_query).to receive(:likes_change_since_last_week)

#       service.send(:store_likes_counts) # Using `send` to call a private method

#       # Verify the instance variables are set as expected
#       expect(service.instance_variable_get(:@likes_count)).to eq(300)
#       expect(service.instance_variable_get(:@likes_change_since_last_week)).to eq("10% increase")
#       expect(service.instance_variable_get(:@likes_comparison_days)).to eq(7)
#     end
#   end

#   describe '#store_follower_counts' do
#     let(:followers_query) { instance_double(Twitter::TwitterUserMetricsQuery) }

#     before do
#       allow(Twitter::TwitterUserMetricsQuery).to receive(:new).with(user).and_return(followers_query)

#       # Stub the methods and set expectations
#       allow(followers_query).to receive(:followers_count).and_return(500)
#       allow(followers_query).to receive(:followers_count_change_percentage).and_return(5)
#     end

#     it 'retrieves follower counts and formats change percentage correctly' do
#       # Expectations to ensure the methods exist and are called
#       expect(followers_query).to receive(:followers_count)
#       expect(followers_query).to receive(:followers_count_change_percentage)

#       service.send(:store_follower_counts) # Using `send` to call a private method

#       # Verify the instance variables are set as expected
#       expect(service.instance_variable_get(:@followers_count)).to eq(500)
#       expect(service.instance_variable_get(:@followers_count_change_percentage_text)).to eq("5% increase")
#       expect(service.instance_variable_get(:@followers_comparison_days)).to eq(7)
#     end
#   end

#   describe '#store_engagement_rate_graph_data' do
#     let(:engagement_data) do
#       [
#         { date: Date.new(2024, 3, 15), engagement_rate_percentage: 2.51 },
#         { date: Date.new(2024, 3, 16), engagement_rate_percentage: 1.22 },
#         { date: Date.new(2024, 3, 17), engagement_rate_percentage: 1.14 },
#         { date: Date.new(2024, 3, 18), engagement_rate_percentage: 0.77 },
#         { date: Date.new(2024, 3, 19), engagement_rate_percentage: 0.4 }
#       ]
#     end

#     before do
#       allow(Twitter::TweetMetricsQuery).to receive(:new).with(user: user).and_return(tweet_metrics_query)
#       allow(tweet_metrics_query).to receive(:engagement_rate_percentage_per_day).and_return(engagement_data)
#     end

#     it 'retrieves and stores engagement rate percentage per day' do
#       expect(tweet_metrics_query).to receive(:engagement_rate_percentage_per_day)

#       service.send(:store_engagement_rate_graph_data) # Using `send` to call a private method

#       # Verify the instance variable is set as expected
#       expect(service.instance_variable_get(:@engagement_rate_percentage_per_day)).to eq(engagement_data)
#     end
#   end

#   describe '#store_impressions_graph_data' do
#     let(:service_with_admin) { described_class.new(handle: identity.handle, current_user: current_user,  current_admin_user: admin_user) }
#     let(:service_without_admin) { described_class.new(handle: identity.handle, current_user: current_user,  current_admin_user: nil) }

#     let(:impression_data) do
#       [
#         { date: Date.new(2024, 3, 16), impression_count: 2149 },
#         { date: Date.new(2024, 3, 17), impression_count: 51817 },
#         { date: Date.new(2024, 3, 18), impression_count: 72352 },
#         { date: Date.new(2024, 3, 19), impression_count: 29071 }
#       ]
#     end
#     let(:first_day_impression) { { date: Date.new(2024, 3, 16), impression_count: 2149 } }

#     before do
#       allow(Twitter::TweetMetricsQuery).to receive(:new).with(user: user).and_return(tweet_metrics_query)
#       allow(tweet_metrics_query).to receive(:impression_counts_per_day).and_return(impression_data)
#       allow(tweet_metrics_query).to receive(:first_day_impressions).and_return(first_day_impression)
#     end

#     context 'when there is a current admin user' do
#       it 'stores impressions graph data with admin-specific data' do
#         service_with_admin.send(:store_impressions_graph_data)

#         expect(service_with_admin.instance_variable_get(:@impression_formatted_labels_for_graph)).to eq(["Mar 16 (2149)", "Mar 17 (51817)", "Mar 18 (72352)", "Mar 19 (29071)"])
#         expect(service_with_admin.instance_variable_get(:@impression_daily_data_points_for_graph)).to eq([2149, 51817, 72352, 29071])
#         expect(service_with_admin.instance_variable_get(:@first_impressions_message)).to eq("Based on 2149 on 2024-03-16 ")
#       end
#     end

#     context 'when there is no current admin user' do
#       it 'stores impressions graph data without admin-specific data' do
#         service_without_admin.send(:store_impressions_graph_data)

#         expect(service_without_admin.instance_variable_get(:@impression_formatted_labels_for_graph)).to eq(["Mar 16", "Mar 17", "Mar 18", "Mar 19"])
#         expect(service_without_admin.instance_variable_get(:@impression_daily_data_points_for_graph)).to eq([2149, 51817, 72352, 29071])
#         expect(service_without_admin.instance_variable_get(:@first_impressions_message)).to be_nil
#       end
#     end
#   end

# end
