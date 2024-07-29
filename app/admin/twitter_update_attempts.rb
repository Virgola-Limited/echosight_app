ActiveAdmin.register TwitterUpdateAttempt do
  belongs_to :user_twitter_data_update, optional: true
  navigation_menu :default

  filter :user_twitter_data_update_id
  filter :created_at
  filter :updated_at
  filter :error_message, as: :select, collection: [['Present', 'present'], ['Not Present', 'not_present']], label: 'Error Message'
  filter :status

  index do
    column :id
    column :user_twitter_data_update_id
    column :created_at
    column :updated_at
    column :error_message
    column :status
    actions
  end

  show do
    attributes_table do
      row :id
      row :user_twitter_data_update
      row :created_at
      row :updated_at
      row :error_message
      row :status
    end
  end
end
