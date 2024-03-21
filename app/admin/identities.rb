ActiveAdmin.register Identity do
  permit_params :user_id, :created_at, :updated_at, :description, :handle, :image_data, :banner_data

  actions :index, :show, :destroy  # Changed :delete to :destroy

  index do
    selectable_column
    id_column
    column :user_id
    column :created_at
    column :updated_at
    column :description
    column :handle
    actions  # Ensure this is added to display the default actions including the delete option
  end

  filter :handle

  form do |f|
    f.inputs do
      f.input :description
      f.input :handle
    end
    f.actions
  end
end
