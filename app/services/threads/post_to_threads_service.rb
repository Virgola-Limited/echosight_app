module Threads
  class PostToThreadsService
    def initialize
      @client = Threads::API::Client.new(
        access_token: Rails.application.credentials.dig(:app_id, :access_token),
        app_id: Rails.application.credentials.dig(:app_id, :app_id),
        app_secret: Rails.application.credentials.dig(:app_id, :app_secret)
      )
    end

    def call
      # Step 1: Create a text-only post (media container)
      pending_thread = @client.create_thread(text: 'Hello, this is a test post to Threads!')  # replace with your desired text

      # Step 2: Publish the thread
      response = @client.publish_thread(pending_thread.id)

      if response.success?
        puts 'Post successfully created!'
      else
        log_error(response)
      end
    rescue StandardError => e
      puts "An error occurred: #{e.message}"
    end

    private

    def log_error(response)
      puts "Error creating post: Status #{response.status}"
      puts "Error message: #{response.error.message}" if response.error.respond_to?(:message)
      puts "Response headers: #{response.headers}" if response.respond_to?(:headers)
      puts "Response body: #{response.body}" if response.respond_to?(:body)
    end
  end
end
