module AuthenticationHelper
  def login_user(user = nil)
    user = create(:user) if user.nil?
    login_as(user, scope: :user)
    user
  end

  def simulate_twitter_connection(user)
    identity = create(:identity, user: user)
    user.update!(name: 'Twitter User')
    identity
  end

  def logout_user(user)
    click_on 'User Avatar'
    click_link 'Sign out'
  end
end
