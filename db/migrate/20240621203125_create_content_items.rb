class CreateContentItems < ActiveRecord::Migration[7.1]
  def change
    create_table :content_items do |t|
      t.text :content, null: false
      t.text :image_data
      t.string :category

      t.timestamps
    end
  end
end
