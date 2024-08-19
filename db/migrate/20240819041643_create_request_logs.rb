class CreateRequestLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :request_logs do |t|
      t.string :endpoint, null: false
      t.jsonb :params, null: false, default: {}
      t.jsonb :response, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end

    add_index :request_logs, :endpoint
    add_index :request_logs, :created_at
  end
end
