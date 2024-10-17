# db/migrate/20240807_create_searches.rb
class CreateSearches < ActiveRecord::Migration[6.1]
  def change
    create_table :searches do |t|
      t.references :user, null: false, foreign_key: true
      t.string :keywords, null: false
      t.string :platform, null: false, default: 'twitter' # or 'threads'
      t.datetime :last_searched_at

      t.timestamps
    end
  end
end
