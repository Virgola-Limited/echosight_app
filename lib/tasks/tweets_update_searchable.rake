namespace :tweets do
  desc "Update searchable column for all tweets"
  task update_searchable: :environment do
    Tweet.find_each(batch_size: 1000) do |tweet|
      Tweet.connection.execute <<-SQL.squish
        UPDATE tweets
        SET searchable = to_tsvector('english', #{ActiveRecord::Base.connection.quote(tweet.text)})
        WHERE id = #{tweet.id}
      SQL
    end
  end
end
