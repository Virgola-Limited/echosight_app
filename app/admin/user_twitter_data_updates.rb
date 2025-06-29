ActiveAdmin.register UserTwitterDataUpdate do
  actions :index, :show, :delete  # Makes the resource read-only

  filter :identity_user_id, as: :select, collection: -> { User.all.map { |u| [u.email, u.id] } }
  filter :error_message, as: :select, collection: [['Present', 'present'], ['Not Present', 'not_present']], label: 'Error Message'
  filter :retry_count

  index do
    column :id
    column :created_at
    column :identity_id
    column "User Email" do |user_twitter_data_update|
      if user_twitter_data_update.identity && user_twitter_data_update.identity.user
        link_to user_twitter_data_update.identity.user.email, admin_user_path(user_twitter_data_update.identity.user)
      else
        "No User"
      end
    end
    column :started_at
    column :retry_count
    column :completed_at
    column "Error Message", :error_message do |update|
      span truncate(update.error_message, length: 300), title: update.error_message
    end
    column :sync_class
    column "API Batch ID", :api_batch_id do |update|
      link_to update.api_batch_id, admin_api_batch_path(update.api_batch_id) if update.api_batch_id
    end
    column "Twitter Update Attempts" do |user_twitter_data_update|
      link_to "View Attempts", admin_user_twitter_data_update_twitter_update_attempts_path(user_twitter_data_update, q: { user_twitter_data_update_id_eq: user_twitter_data_update.id })
    end
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :identity_id
      row :started_at
      row :completed_at
      row :error_message
      row :sync_class
      row :api_batch_id
      row :created_at
      row :updated_at
    end
  end
end
