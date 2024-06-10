# app/admin/feature_requests.rb
ActiveAdmin.register FeatureRequest do
  permit_params :title, :description, :user_id

  index do
    selectable_column
    id_column
    column :title
    column :description
    column :user
    column :created_at
    column :updated_at
    actions
  end

  filter :title
  filter :description
  filter :user
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs do
      f.input :title
      f.input :description
      f.input :user, as: :select, collection: User.all.collect { |user| [user.email, user.id] }
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :title
      row :description
      row :user
      row :created_at
      row :updated_at
    end
  end
end
