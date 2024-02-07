ActiveAdmin.register TwitterFollowersCount do
  actions :index, :show

  index do
    column :id
    column :followers_count
    column :identity_id
    column :date
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :followers_count
      row :identity_id
      row :date
      row :created_at
      row :updated_at
    end
  end
end
