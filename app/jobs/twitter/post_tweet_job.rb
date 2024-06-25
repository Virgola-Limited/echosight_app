module Twitter
  class PostTweetJob
    include Sidekiq::Job
    sidekiq_options retry: false

    def perform(content_item_id)
      content_item = ContentItem.find(content_item_id)
      user = User.find(content_item.user_id) # Assuming the user_id field exists on ContentItem

      text = content_item.content
      image_url = content_item.image_url.present? ? "#{Rails.application.credentials[:asset_host]}#{content_item.image_url}" : nil

      post_service = Twitter::PostService.new(user, text, image_url)
      post_service.call
    end
  end
end