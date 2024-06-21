class AddTitleToContentItem < ActiveRecord::Migration[7.1]
  def change
    add_column :content_items, :title, :string
  end
end
