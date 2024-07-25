# app/admin/ad_campaigns.rb
ActiveAdmin.register AdCampaign do
  permit_params :name, :utm_source

  index do
    selectable_column
    id_column
    column :name
    column :campaign_id
    column :utm_source
    column "Campaign URL" do |ad_campaign|
      link_to "View Campaign", "https://app.echosight.io/?campaign_id=#{ad_campaign.campaign_id}", target: "_blank"
    end
    actions
  end

  filter :name
  filter :utm_source

  form do |f|
    f.inputs do
      f.input :name
      f.input :utm_source, as: :select, collection: AdCampaign.validators_on(:utm_source).find { |v| v.is_a?(ActiveModel::Validations::InclusionValidator) }.options[:in]
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
