# frozen_string_literal: true

class PublicPagesController < ApplicationController
  include Cacheable

  def show
    if params[:handle] == 'demo' && current_user&.identity.present?
      redirect_to public_page_path(current_user.identity.handle) and return
    end

    public_page_data = PublicPageService.call(handle: params[:handle], current_user: current_or_guest_user, current_admin_user: current_admin_user)
    if public_page_data.demo? && current_or_guest_user.guest?
      sign_up_link = view_context.link_to('Sign up', new_user_registration_path).html_safe
      flash.now[:notice] = "This is a demo page showing how your public page could look. #{sign_up_link} to get your own!".html_safe
    elsif !current_user.enough_data_for_public_page?
      flash.now[:notice] = "We haven't collected enough data to make your public page look great yet. Please check back later.".html_safe
    end

    render PublicPageComponent.new(public_page_data: public_page_data, current_user: current_or_guest_user)
  end
end
