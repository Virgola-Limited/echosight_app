ActiveAdmin.register ContentItem do
  permit_params :content, :category, :image, :title, :user_id

  index do
    selectable_column
    id_column
    column :title
    column :content
    column :category
    column :user
    actions
  end

  filter :content
  filter :category
  filter :user

  form do |f|
    f.inputs do
      f.input :title
      f.input :content
      f.input :category, input_html: { value: f.object.category || 'app_update' }
      f.input :image, as: :file
      f.input :user, as: :select, collection: User.all.map { |u| [u.email, u.id] }
    end
    f.actions
  end
end
