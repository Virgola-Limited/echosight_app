class AddUserIdToBugReports < ActiveRecord::Migration[7.1]
  def change
    add_reference :bug_reports, :user, null: false, foreign_key: true
  end
end
