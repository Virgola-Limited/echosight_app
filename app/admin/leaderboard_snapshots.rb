ActiveAdmin.register LeaderboardSnapshot do
  permit_params :date_range, :captured_at

  index do
    selectable_column
    id_column
    column :date_range
    column :captured_at
    column :created_at
    column :updated_at
    actions
  end

  filter :date_range
  filter :captured_at
  filter :created_at
  filter :updated_at

  form do |f|
    f.inputs do
      f.input :date_range
      f.input :captured_at
    end
    f.actions
  end

  show do
    attributes_table do
      row :date_range
      row :captured_at
      row :created_at
      row :updated_at
    end
    active_admin_comments
  end
end
