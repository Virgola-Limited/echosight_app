# app/controllers/tracker_controller.rb
class TrackerController < ApplicationController
  def open
    tracking_id = params[:tracking_id]
    sent_email = SentEmail.find_by(tracking_id: tracking_id)

    if sent_email && !sent_email.opened
      sent_email.update(opened: true, opened_at: Time.current)
    end

    # Return a 1x1 pixel transparent image
    send_data(Base64.decode64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/wcAAwAB/iiP4tAAAAAASUVORK5CYII='), type: 'image/png', disposition: 'inline')
  end
end
