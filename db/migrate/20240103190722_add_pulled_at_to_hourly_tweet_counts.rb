# frozen_string_literal: true

class AddPulledAtToHourlyTweetCounts < ActiveRecord::Migration[7.1]
  def change
    add_column :tweet_hourly_counts, :pulled_at, :datetime
  end
end
