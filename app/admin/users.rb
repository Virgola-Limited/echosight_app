ActiveAdmin.register User do
  permit_params :name, :last_name, :email, :vip_since, :enabled_without_subscription, :ad_campaign_id

  actions :index, :show, :edit, :update, :destroy

  filter :email
  filter :ad_campaign_id_present, as: :boolean, label: 'Has Campaign ID'

  controller do
    def scoped_collection
      super.includes(:ad_campaign)
    end
  end

  index do
    column :id
    column :name
    column :last_name
    column :email
    column :created_at
    column "Sign<br>In<br>Count".html_safe, :sign_in_count
    column :current_sign_in_at
    column :last_sign_in_at
    column 'Identity<br>Handle'.html_safe do |user|
      user.identity.try(:handle) # Assumes that the Identity model has a 'handle' attribute
    end
    column "VIP", :vip_since
    column 'Enabled<br>w/o<br>Sub'.html_safe, :enabled_without_subscription

    column :can_dm
    column 'Campaign' do |user|
      if user.ad_campaign
        link_to user.ad_campaign.name, admin_ad_campaign_path(user.ad_campaign)
      else
        'No Campaign'
      end
    end
    actions defaults: true do |user|
      item 'Masquerade', masquerade_path(user), method: :post if user.sign_in_count > 0
      if user.otp_required_for_login
        item 'Disable 2FA', disable_2fa_admin_user_path(user), method: :put
      end
    end
  end

  show do
    attributes_table do
      row :name
      row :last_name
      row :email
      row :created_at
      row :updated_at
      row :sign_in_count
      row :current_sign_in_at
      row :last_sign_in_at
      row 'Identity Handle' do |user|
        user.identity.try(:handle)
      end
      row :vip_since
      row :enabled_without_subscription
      row :can_dm
    end
  end

  form do |f|
    f.inputs 'User Details' do
      f.input :name
      f.input :last_name
      f.input :email
      f.input :vip_since
      f.input :enabled_without_subscription
      f.input :ad_campaign_id
    end
    f.actions
  end

  member_action :disable_2fa, method: :put do
    user = User.find(params[:id])
    user.update(otp_secret: nil, otp_required_for_login: false)
    redirect_to admin_users_path, notice: '2FA has been disabled for the user.'
  end

  collection_action :invite_user, method: :get do
    @user = User.new
    render 'admin/users/invite_user'
  end

  collection_action :send_invite, method: :post do
    user = User.invite!(email: params[:user][:email], name: params[:user][:name])
    if user.errors.empty?
      redirect_to admin_users_path, notice: 'User has been successfully invited.'
    else
      flash[:error] = user.errors.full_messages.join(', ')
      redirect_to invite_user_admin_users_path
    end
  end

  action_item :invite, only: :index do
    link_to 'Invite User', invite_user_admin_users_path
  end
end
