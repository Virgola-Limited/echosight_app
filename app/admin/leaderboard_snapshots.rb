ActiveAdmin.register LeaderboardSnapshot do
  permit_params :captured_at

  index do
    selectable_column
    id_column
    column :captured_at
    column :created_at
    column :updated_at
    actions
  end

  filter :captured_at
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs do
      f.input :captured_at
    end
    f.actions
  end

  show do
    attributes_table do
      row :captured_at
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end
