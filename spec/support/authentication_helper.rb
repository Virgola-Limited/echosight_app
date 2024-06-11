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

  # def warden_scope(resource)
  #   resource.class.name.underscore.to_sym
  # end

  def logout_user(user)
    raise 'doesnt work'
    scope = warden_scope(user)
    logout(scope)
  end
end
