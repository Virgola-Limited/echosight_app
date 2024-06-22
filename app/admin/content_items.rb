ActiveAdmin.register ContentItem do
  permit_params :content, :category, :image, :title

  index do
    selectable_column
    id_column
    column :title
    column :content
    column :category
    actions
  end

  filter :content
  filter :category

  form do |f|
    f.inputs do
      f.input :title
      f.input :content
      f.input :category, input_html: { value: f.object.category || 'app_update' }
      f.input :image, as: :file
    end
    f.actions
  end
end
