# frozen_string_literal: true

class PublicPagesController < ApplicationController
  include Cacheable

  # if handle its the public url
  # if no handle and logged in its them looking at their own page so dont 404
  # show either their page or demo page

  # alway show the current users page if the user is my_public_page?
  # Only make the url my_public_page if they havent connected to their twitter account. (no identity?)
  def show
    if params[:handle] == 'mine' && current_user&.identity.present?
      redirect_to public_page_path(current_user.identity.handle) and return
    end

    public_page_data = PublicPageService.call(handle: params[:handle], current_user: current_or_guest_user, current_admin_user: current_admin_user)

    if public_page_data.is_a?(PublicPageService::Result)
      case public_page_data.status
      when :error
        flash[:alert] = public_page_data.message
        redirect_to public_page_data.redirect_path and return
      when :demo
        flash[:notice] = "This is a demo page showing how your public page could look."
      end
    else
      # Handle the successful case
      @cache_key = cache_key_for_user(public_page_data.user)
      render PublicPageComponent.new(public_page_data: public_page_data, current_user: current_or_guest_user)
    end
  end


end
