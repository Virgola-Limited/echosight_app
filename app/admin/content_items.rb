# app/admin/content_items.rb
ActiveAdmin.register ContentItem do
  permit_params :content, :category, image: []

  index do
    selectable_column
    id_column
    column :content
    column :image_data
    column :category
    actions
  end

  filter :content
  filter :category, as: :select, collection: -> { ContentItem.distinct.pluck(:category) }

  form do |f|
    f.inputs do
      f.input :content
      f.input :image_data, as: :file
      f.input :category
    end
    f.actions
  end

  show do
    attributes_table do
      row :content
      row :image do |ad|
        image_tag(ad.image.url) if ad.image
      end
      row :category
    end
  end
end
