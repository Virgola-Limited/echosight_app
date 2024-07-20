# frozen_string_literal: true

class PublicPagesController < ApplicationController
  include Cacheable

  def show
    if params[:handle] == 'demo' && current_user&.identity.present?
      redirect_to public_page_path(current_user.identity.handle) and return
    end

    date_range = params[:date_range]
    @public_page_data = PublicPageService.call(
      handle: params[:handle],
      current_user: current_or_guest_user,
      current_admin_user: current_admin_user,
      date_range: date_range
    )
    set_flash_message
    @page_updated_at = @public_page_data.last_cache_update

    render PublicPageComponent.new(public_page_data: @public_page_data, current_user: current_or_guest_user)
  end

  private

  def set_flash_message
    # Not logged In
    ###############
    if current_or_guest_user.guest?
      # 1 Demo Page
      if @public_page_data.demo?
        link = view_context.link_to('Sign up', new_user_registration_path).html_safe
        flash.now[:notice] = "This is a demo page showing how your public page could look. #{link} to get your own!".html_safe
        return
      end
      if @public_page_data.user.syncable? # Is this correct?
        # 2 Users public page active subscription
        return
      else
      # 3 Users public page without active subscription
      link = view_context.link_to('Sign up', new_user_registration_path).html_safe
      flash.now[:notice] = "This is an inactive public page. #{link} to get your own Echosight public page.".html_safe
      end
    else
      # Logged In
      ###############
      link = view_context.link_to('Dashboard', dashboard_index_path).html_safe
      # 1 Demo page
      if @public_page_data.demo?
        flash.now[:notice] = "This is a demo or inactive page showing how your public page could look. Check your #{link} for the steps to enable your public page.".html_safe
        return
      end
      if @public_page_data.user.syncable?
        # 2 Users public page active subscription
      else
        # 3 Users public page without active subscription
        flash.now[:notice] = "Check your #{link} for the steps to enable your public page.".html_safe
      end
    end
  end
end