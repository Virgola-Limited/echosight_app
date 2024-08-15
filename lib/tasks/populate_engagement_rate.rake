namespace :tweet_metrics do
  desc "Populate engagement_rate for existing TweetMetric records in batches"
  task populate_engagement_rate: :environment do
    batch_size = 1000
    total_count = TweetMetric.count
    processed_count = 0

    TweetMetric.find_in_batches(batch_size: batch_size) do |batch|
      ActiveRecord::Base.transaction do
        batch.each do |metric|
          metric.send(:calculate_engagement_rate)
          metric.save(validate: false)
        end
      end

      processed_count += batch.size
      progress = (processed_count.to_f / total_count * 100).round(2)
      puts "Processed #{processed_count}/#{total_count} records (#{progress}%)"
    end

    puts "Finished populating engagement_rate for all TweetMetric records."
  end
end