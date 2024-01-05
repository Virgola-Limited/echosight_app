# frozen_string_literal: true

class CreateTweetDailyCounts < ActiveRecord::Migration[7.1]
  def change
    create_table :tweet_daily_counts do |t|
      t.references :identity, null: false, foreign_key: true
      t.date :date
      t.integer :tweet_count

      t.timestamps
    end
  end
end
