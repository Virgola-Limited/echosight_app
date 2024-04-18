class AddCompleteFirstDayPulledAtToTweetMetric < ActiveRecord::Migration[7.1]
  def change
    add_column :tweet_metrics, :complete_first_day_pulled_at, :datetime
  end
end
