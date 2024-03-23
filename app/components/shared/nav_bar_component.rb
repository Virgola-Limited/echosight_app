module Shared
  class NavBarComponent < ViewComponent::Base
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def demo_or_real_public_page_link
      # <a target="_blank" href="<%= current_or_guest_user.handle ? public_page_url(current_or_guest_user.handle) : '#' %>" class="block rounded text-primary-700 dark:text-primary-500" aria-current="page">My Public Page</a>

    end

  end
end