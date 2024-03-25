module AuthenticationHelper
  def login_user(user = nil)
    user = create(:user) if user.nil?
    login_as(user, scope: :user)
    user
  end

  def simulate_twitter_connection(user)
    create(:identity, user: user)
    user.update!(name: 'Twitter User')
  end
end