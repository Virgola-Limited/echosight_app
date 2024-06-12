class SitemapController < ApplicationController
  def index
    identities = Identity.syncable
    @users = identities.map(&:user).compact
    respond_to do |format|
      format.xml
    end
  end
end