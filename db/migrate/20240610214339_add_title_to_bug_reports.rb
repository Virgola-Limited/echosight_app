class AddTitleToBugReports < ActiveRecord::Migration[7.1]
  def change
    add_column :bug_reports, :title, :string
  end
end
