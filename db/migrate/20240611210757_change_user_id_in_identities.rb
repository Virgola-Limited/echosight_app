class ChangeUserIdInIdentities < ActiveRecord::Migration[7.1]
  def change
    change_column_null :identities, :user_id, true
  end
end
