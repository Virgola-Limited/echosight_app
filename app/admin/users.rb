ActiveAdmin.register User do
  permit_params :name, :last_name, :email

  actions :index, :show, :edit, :update

  filter :email

  index do
    column :name
    column :last_name
    column :email
    column :created_at
    column :sign_in_count
    column :current_sign_in_at
    column :last_sign_in_at
    column "Identity Handle" do |user|
      user.identity.try(:handle) # Assumes that the Identity model has a 'handle' attribute
    end
    column :vip_since
    actions
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
      # Include other fields as needed
    end
  end

  form do |f|
    f.inputs 'User Details' do
      f.input :name
      f.input :last_name
      f.input :email
      f.input :vip_since
    end
    f.actions
  end

  controller do
    def update
      super do |format|
        if resource.valid? && resource.unconfirmed_email.present?
          resource.confirm  # Manually confirm the new email
          redirect_to admin_user_path(resource) and return if resource.errors.blank?
        end
      end
    end
  end

  collection_action :invite_user, method: :get do
    @user = User.new # Initializes a new user for the form

    render 'admin/users/invite_user'
  end

  collection_action :send_invite, method: :post do
    user = User.invite!(email: params[:user][:email], name: params[:user][:name]) # Adjust as per your User model attributes
    if user.errors.empty?
      redirect_to admin_users_path, notice: "User has been successfully invited."
    else
      flash[:error] = user.errors.full_messages.join(", ")
      redirect_to invite_user_admin_users_path
    end
  end

  action_item :invite, only: :index do
    link_to 'Invite User', invite_user_admin_users_path
  end
end
