ActiveAdmin.register User do
  actions :index, :show  # Makes the resource read-only

  filter :email

  index do
    column :name
    column :last_name
    column :email
    column :created_at
    column :updated_at
    column :sign_in_count
    column :current_sign_in_at
    column :last_sign_in_at
    actions
  end

  show do
    attributes_table do
      row :name
      row :last_name
      row :email
      row :created_at
      row :updated_at
      row :sign_in_count
      row :current_sign_in_at
      row :last_sign_in_at
      # Include other fields as needed
    end
  end
end
