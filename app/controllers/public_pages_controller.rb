# frozen_string_literal: true

class PublicPagesController < ApplicationController
  include Cacheable

  def show
    if params[:handle] == 'demo' && current_user&.identity.present?
      redirect_to public_page_path(current_user.identity.handle) and return
    end

    @public_page_data = PublicPageService.call(handle: params[:handle], current_user: current_or_guest_user, current_admin_user: current_admin_user)
    set_flash_message

    render PublicPageComponent.new(public_page_data: @public_page_data, current_user: current_or_guest_user)
  end

  private

  def set_flash_message
    if @public_page_data.demo?
      link = view_context.link_to('Sign up', new_user_registration_path).html_safe

      # handle logged out user on demo page
      if current_or_guest_user.guest?
        link = view_context.link_to('Sign up', new_user_registration_path).html_safe
      else
        unless current_or_guest_user.active_subscription?
          link = view_context.link_to('Subscribe', new_subscription_path).html_safe
        end

      end
      flash.now[:notice] = "This is a demo page showing how your public page could look. #{link} to get your own!".html_safe
      return
    end

    # TODO: handle public page where data is lacking for logged out users

    # handle logged in user with no subscription
    if @public_page_data.owns_page && !current_or_guest_user.active_subscription?
      link = view_context.link_to('Subscribe', new_subscription_path).html_safe
      flash.now[:notice] = "#{link} to start pulling #{t(:twitter_title)} data into your public page!".html_safe
      return
    end
  end
end