# frozen_string_literal: true

class CreateTweetHourlyCounts < ActiveRecord::Migration[7.1]
  def change
    create_table :tweet_hourly_counts do |t|
      t.references :identity, null: false, foreign_key: true
      t.datetime :start_time
      t.datetime :end_time
      t.integer :tweet_count

      t.timestamps
    end
  end
end
