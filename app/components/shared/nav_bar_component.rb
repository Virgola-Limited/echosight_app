module Shared
  class NavBarComponent < ViewComponent::Base
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def demo_or_real_public_page_link
      # if the user has an identity handle, link to their public page via the handle
      # otherwise use mine_path
      user.handle.present? ? public_page_path(user.handle : public_page_path(:mine)
    end

    def nav_links
      [
        { name: 'Dashboard', path: root_url },
        { name: 'My Public Page', path: demo_or_real_public_page_link },
        { name: 'My Profile & Settings', path: edit_user_registration_path }
      ]
    end
  end
end