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
    # Rails.logger.debug('paul demo' + @public_page_data.demo?.inspect)

    if @public_page_data.demo?
      if current_or_guest_user.guest?
        link = view_context.link_to('Sign up', new_user_registration_path).html_safe
        flash.now[:notice] = "This is a demo or inactive page showing how your public page could look. #{link} to get your own!".html_safe if link
      else
        unless current_or_guest_user.syncable?
          link = view_context.link_to('Dashboard', dashboard_index_path).html_safe
          flash.now[:notice] = "Check your #{link} for the steps to enable your public page.".html_safe
        end
      end
    else
      if current_or_guest_user.guest?
        link = view_context.link_to('Sign up', new_user_registration_path).html_safe
        flash.now[:notice] = "This is a demo or inactive page showing how your public page could look. #{link} to get your own!".html_safe if link
      else
        unless current_or_guest_user.syncable?
          link = view_context.link_to('Dashboard', dashboard_index_path).html_safe
          flash.now[:notice] = "Check your #{link} for the steps to enable your public page.".html_safe
        end
      end
    end

    # TODO: handle public page where data is lacking for logged out users
  end
end