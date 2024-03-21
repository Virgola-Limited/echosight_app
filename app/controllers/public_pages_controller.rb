# frozen_string_literal: true

class PublicPagesController < ApplicationController
  include Cacheable

  def show
    identity = Identity.find_by(handle: params['handle'])
    @user = identity.user if identity.present?

    raise ActiveRecord::RecordNotFound if @user.nil?
    @cache_key = cache_key_for_user(@user)

    @public_page_service = PublicPageService.call(user: @user, current_admin_user: current_admin_user)
  end

end
