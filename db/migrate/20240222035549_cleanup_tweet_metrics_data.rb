class CleanupTweetMetricsData < ActiveRecord::Migration[7.1]
  def up
    TweetMetric.find_each do |tm|
      # Group by tweet_id and the date part of pulled_at, then keep only the latest record for each day
      duplicates = TweetMetric.where(tweet_id: tm.tweet_id)
                              .where('DATE(pulled_at) = ?', tm.pulled_at.to_date)
                              .where.not(id: tm.id)
                              .order(pulled_at: :desc)

      # Keep only the last record of the day, delete the rest
      duplicates.where.not(id: duplicates.last.id).destroy_all if duplicates.exists?
    end
  end

  def down
    # Data cleanup migration cannot be easily reversed
    raise ActiveRecord::IrreversibleMigration
  end
end