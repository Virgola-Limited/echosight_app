class SitemapController < ApplicationController
  def index
    @users = User.syncable
    respond_to do |format|
      format.xml
    end
  end
end