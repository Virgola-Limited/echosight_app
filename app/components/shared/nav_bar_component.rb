module Shared
  class NavBarComponent < ApplicationComponent
    attr_reader :user, :current_admin_user

    def initialize(user:, current_admin_user:)
      @user = user
      @current_admin_user = current_admin_user
    end

    def demo_or_real_public_page_link
      user.handle.present? ? public_page_path(user.handle) : public_page_path(:demo)
    end

    def nav_links
      [
        { name: 'Dashboard', path: root_url },
        { name: 'My Public Page', path: demo_or_real_public_page_link },
        { name: 'My Posts', path: posts_path },
        { name: 'Leaderboard', path: leaderboard_path },
        { name: 'Feature Requests', path: feature_requests_path }
        { name: 'FAQ', path: faq_path}
      ]
    end
  end
end
