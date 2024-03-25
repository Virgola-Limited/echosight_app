module AuthenticationHelper
  def login_user(user = nil)
    user = create(:user) if user.nil?
    login_as(user, scope: :user)
    user
  end
end