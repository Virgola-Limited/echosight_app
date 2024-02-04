ActiveAdmin.register User do
  permit_params :name, :last_name, :email

  actions :index, :show, :edit, :update

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

  form do |f|
    f.inputs 'User Details' do
      f.input :name
      f.input :last_name
      f.input :email
      # Add other inputs here if needed
    end
    f.actions
  end

  controller do
    def update
      super do |format|
        if resource.valid? && resource.unconfirmed_email.present?
          resource.confirm  # Manually confirm the new email
          redirect_to admin_user_path(resource) and return if resource.errors.blank?
        end
      end
    end
  end
end
