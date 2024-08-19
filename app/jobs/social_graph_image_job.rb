# app/jobs/generate_social_graph_image_job.rb
class GenerateSocialGraphImageJob < ApplicationJob
  queue_as :default

  def perform(user)
    image_url = SocialGraphImageService.generate_image(user)
    # Store the generated image URL, maybe in the user's model or another model
    user.update!(social_graph_image_url: image_url)
  end
end
