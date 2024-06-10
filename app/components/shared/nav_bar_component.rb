module Shared
  class NavBarComponent < ApplicationComponent
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def demo_or_real_public_page_link
      user.handle.present? ? public_page_path(user.handle) : public_page_path(:demo)
    end

    def nav_links
      [
        { name: 'Dashboard', path: root_url },
        { name: 'My Public Page', path: demo_or_real_public_page_link },
        { name: 'Subscription', path: subscription_path },
        { name: 'Feature Requests', path: feature_requests_path }
      ]
    end
  end
end