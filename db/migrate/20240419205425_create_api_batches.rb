class CreateApiBatches < ActiveRecord::Migration[7.1]
  def change
    create_table :api_batches do |t|
      t.datetime :completed_at
      t.string :status, default: 'pending'

      t.timestamps
    end
  end
end
