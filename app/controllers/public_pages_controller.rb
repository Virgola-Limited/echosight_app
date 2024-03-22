# frozen_string_literal: true

class PublicPagesController < ApplicationController
  include Cacheable

  # if handle its the public url
  # if no handle and logged in its them looking at their own page so dont 404
  # show either their page or demo page

  # alway show the current users page if the user is my_public_page?
  # Only make the url my_public_page if they havent connected to their twitter account. (no identity?)
  def show
    identity = Identity.find_by(handle: params['handle'])
    @user = identity.user if identity.present?
    if @user.nil?
      raise ActiveRecord::RecordNotFound unless current_user
      @user = current_user
    end
    @cache_key = cache_key_for_user(@user)

    public_page_data = PublicPageService.call(user: @user, current_admin_user: current_admin_user)
    render PublicPageComponent.new(public_page_data: public_page_data, current_user: current_or_guest_user)
  end

end
