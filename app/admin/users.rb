ActiveAdmin.register User do
  permit_params :name, :last_name, :email, :vip_since, :enabled_without_subscription, :ad_campaign_id

  actions :index, :show, :edit, :update

  filter :email
  filter :ad_campaign_id_present, as: :boolean, label: 'Has Campaign ID'

  index do
    column :name
    column :last_name
    column :email
    column :created_at
    column :sign_in_count
    column :current_sign_in_at
    column :last_sign_in_at
    column 'Identity Handle' do |user|
      user.identity.try(:handle) # Assumes that the Identity model has a 'handle' attribute
    end
    column :vip_since
    column :enabled_without_subscription
    column :can_dm
    column :ad_campaign_id
    actions defaults: true do |user|
      if user.otp_required_for_login
        link_to 'Disable 2FA', disable_2fa_admin_user_path(user), method: :put
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
        user.identity.try(:handle) # Assumes that the Identity model has a 'handle' attribute
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
    end
    f.actions
  end

  controller do
    def scoped_collection
      if params[:q] && params[:q][:ad_campaign_id_present]
        if params[:q][:ad_campaign_id_present] == "true"
          super.where.not(ad_campaign_id: nil)
        else
          super.where(ad_campaign_id: nil)
        end
      else
        super
      end
    end

    def update
      super do |_format|
        if resource.valid? && resource.unconfirmed_email.present?
          resource.confirm # Manually confirm the new email
          redirect_to admin_user_path(resource) and return if resource.errors.blank?
        end
      end
    end
  end

  member_action :disable_2fa, method: :put do
    user = User.find(params[:id])
    user.update(otp_secret: nil, otp_required_for_login: false)
    redirect_to admin_users_path, notice: '2FA has been disabled for the user.'
  end

  collection_action :invite_user, method: :get do
    @user = User.new # Initializes a new user for the form

    render 'admin/users/invite_user'
  end

  collection_action :send_invite, method: :post do
    user = User.invite!(email: params[:user][:email], name: params[:user][:name]) # Adjust as per your User model attributes
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
