class RequestLogger
  def self.log(endpoint, params, response, metadata = {})
    return unless should_log?(endpoint, params, response)

    RequestLog.create!(
      endpoint: endpoint,
      params: params,
      response: response,
      metadata: metadata
    )
  end

  def self.should_log?(endpoint, params, response)
    # Implement your logging rules here
    # For example, log when the tweet doesn't match the API search parameters
    response['tweets'].any? { |tweet| tweet.dig('user', 'data', 'id') != params[:identity_uid] }
  end
end