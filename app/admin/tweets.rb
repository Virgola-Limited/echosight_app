ActiveAdmin.register Tweet do
  actions :index, :show  # Makes the resource read-only

  filter :identity_user_id, as: :select, collection: -> { User.all.map { |u| [u.email, u.id] } }

  index do
    column :twitter_id
    column "User Email" do |tweet|
      if tweet.identity && tweet.identity.user
        link_to tweet.identity.user.email, admin_user_path(tweet.identity.user)
      else
        "No User"
      end
    end
    column :text
    column :identity_id
    column :created_at
    column :updated_at
    column :twitter_created_at
    actions
  end

  show do
    attributes_table do
      row :twitter_id
      row :text
      row :identity_id
      row :created_at
      row :updated_at
      row :twitter_created_at
    end
  end
end
