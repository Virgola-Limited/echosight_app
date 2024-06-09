# frozen_string_literal: true

ActiveAdmin.register User do
  permit_params :name, :last_name, :email, :following_on_twitter

  actions :index, :show, :edit, :update

  filter :email

  # Custom sorting
  scope :all, default: true do |users|
    users.joins('LEFT JOIN identities ON users.id = identities.user_id')
         .order('identities.id IS NULL, following_on_twitter ASC')
  end

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
    column :following_on_twitter do |user|
      check_box_tag 'following_on_twitter', '1', user.following_on_twitter, class: 'toggle-following-on-twitter', data: { user_id: user.id }
    end
    column 'Twitter' do |user|
      if user.identity.present?
        link_to 'Twitter Profile', "https://x.com/#{user.identity.handle}", target: '_blank'
      else
        'Missing identity'
      end
    end
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
      user = User.find(params[:id])
      user.update(permitted_params[:user])
      respond_to do |format|
        format.html { redirect_to admin_user_path(user) }
        format.js { head :ok }
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

# Add JavaScript to handle the checkbox toggle with Ajax
js do
  <<-JS
    $(document).on('change', '.toggle-following-on-twitter', function() {
      var userId = $(this).data('user_id');
      var followingOnTwitter = $(this).is(':checked');

      $.ajax({
        type: 'PATCH',
        url: '/users/' + userId,
        data: { user: { following_on_twitter: followingOnTwitter } },
        success: function(response) {
          console.log('Updated successfully');
        },
        error: function(response) {
          console.log('Update failed');
        }
      });
    });
  JS
end
