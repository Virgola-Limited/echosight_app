# app/admin/ad_campaigns.rb
ActiveAdmin.register AdCampaign do
  permit_params :name, :utm_source

  index do
    selectable_column
    id_column
    column :name
    column :campaign_id
    column :utm_source
    actions
  end

  filter :name
  filter :utm_source

  form do |f|
    f.inputs do
      f.input :name
      f.input :utm_source, as: :select, collection: %w[twitter threads instagram]
    end
    f.actions
  end

  show do
    attributes_table do
      row :name
      row :campaign_id
      row :utm_source
    end
    active_admin_comments
  end
end
