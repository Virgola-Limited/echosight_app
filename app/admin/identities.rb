ActiveAdmin.register Identity do
  permit_params :user_id, :created_at, :updated_at, :description, :handle, :image_data, :banner_data

  actions :index, :show, :destroy

  index do
    selectable_column
    id_column
    column :user_id
    column :created_at
    column :updated_at
    column :description
    column :handle

    actions defaults: true do |identity|
      link_to "Public Page", public_page_path(handle: identity.handle), target: "_blank"
    end
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
