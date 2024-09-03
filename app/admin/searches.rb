ActiveAdmin.register Search do
  # Existing permit_params
  permit_params :user_id, :keywords, :platform

  form do |f|
    f.inputs 'Search Details' do
      f.input :keywords
      f.input :user, as: :select, collection: User.order(:email).map { |u| [u.email, u.id] }, include_blank: false
      f.input :platform
    end
    f.actions
  end

  # Eager load associations
  includes :user, :tweets

  # Customize the index
  index do
    selectable_column
    id_column
    column :user
    column :keywords
    column :platform
    column :last_searched_at
    column :tweets do |search|
      search.tweets.count
    end
    actions
  end

  # Optimize the filter
  filter :user
  filter :keywords
  filter :platform, as: :select, collection: Search.platforms

  # Batch actions (if needed)
  batch_action :destroy, confirm: "Are you sure you want to delete these searches?" do |ids|
    batch_action_collection.find(ids).each do |search|
      search.destroy
    end
    redirect_to collection_path, alert: "The searches have been deleted."
  end

end