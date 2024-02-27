# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'chrome-extension://oejebccocpoclmloojpokackdlhdddeh'  # Replace this with the origin of your Chrome extension

    resource '/scraped_contents',
      headers: :any,
      methods: [:post]
  end
end
