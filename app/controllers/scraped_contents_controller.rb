class ScrapedContentsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    # Simulating an error to trigger exception notification
    begin
      raise "Received HTML Content: #{params[:html]}"
    rescue => e
      ExceptionNotifier.notify_exception(e, env: request.env, data: { message: "Received HTML Content" })
    end

    # Respond with success status
    head :ok
  end
end
