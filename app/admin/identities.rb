ActiveAdmin.register Identity do
  permit_params :user_id, :created_at, :updated_at, :description, :handle, :image_data, :banner_data, :uid

  actions :index, :show, :destroy, :new, :edit, :create, :update

  controller do
    def scoped_collection
      super.sorted_by_followers_count
    end

    def apply_sorting(chain)
      params[:order] = 'max_followers_count_desc' if params[:order].blank?
      super
    end
  end

  index do
    selectable_column
    id_column
    column :user_id
    column :uid
    column :created_at
    column :updated_at
    column :description
    column :handle

    column :followers_count do |identity|
      recent_metric = identity.twitter_user_metrics.order(date: :desc).first
      recent_metric ? recent_metric.followers_count : 'N/A'
    end

    column :vip_since do |identity|
      identity.user.vip_since
    end

    actions defaults: true do |identity|
      link_to "Public Page", public_page_path(handle: identity.handle), target: "_blank"
    end
  end

  filter :handle

  form do |f|
    f.inputs do
      f.input :description
      f.input :uid
      f.input :handle
    end
    f.actions
  end
end
