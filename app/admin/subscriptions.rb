ActiveAdmin.register Subscription do
  index do
    selectable_column
    id_column
    column :active
    column :created_at
    column :updated_at
    column :stripe_price_id
    column :stripe_subscription_id
    column :user_id
    actions defaults: true do |subscription|
      link_to "Public Page", public_page_path(handle: subscription.user.identity.handle), target: "_blank"
    end
  end
  # Additional configurations or customizations if needed

end
