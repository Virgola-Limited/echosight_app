# app/controllers/content_items_controller.rb
class ContentItemsController < ApplicationController
  def index
    @content_items = ContentItem.where(category: 'app_update').order(created_at: :desc)
  end
end
