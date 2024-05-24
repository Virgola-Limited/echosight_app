class CreateBugReports < ActiveRecord::Migration[7.1]
  def change
    create_table :bug_reports do |t|

      t.timestamps
    end
  end
end
