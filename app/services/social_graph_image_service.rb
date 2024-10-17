# app/services/social_graph_image_service.rb
class SocialGraphImageService
  def self.generate_image(user, view_context)
    # Render the partial to string
    html_content = view_context.render_to_string(
      partial: "public_pages/social_graph_image",
      locals: { page_user: user }
    )

    file_path = Rails.root.join('tmp', "social_graph_#{user.handle}.png")

    options = { format: 'png', viewport_size: '1200x600' }

    # Use Shrimp to convert the HTML to an image
    pdf = Shrimp::Phantom.new("data:text/html;charset=utf-8,#{CGI.escape(html_content)}", options)
    pdf.to_file(file_path)

    file_path
  end
end
