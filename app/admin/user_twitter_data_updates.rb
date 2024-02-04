ActiveAdmin.register UserTwitterDataUpdate do
  actions :index, :show  # Makes the resource read-only

  filter :identity_user_id, as: :select, collection: -> { User.all.map { |u| [u.email, u.id] } }

  index do
    column :identity_id
    column "User Email" do |user_twitter_data_update|
      if user_twitter_data_update.identity && user_twitter_data_update.identity.user
        link_to user_twitter_data_update.identity.user.email, admin_user_path(user_twitter_data_update.identity.user)
      else
        "No User"
      end
    end
    column :started_at
    column :completed_at
    column :error_message
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :identity_id
      row :started_at
      row :completed_at
      row :error_message
      row :created_at
      row :updated_at
    end
  end
end
