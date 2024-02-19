class SendRateLimitsToSlackJob
  include Sidekiq::Job

  def perform
    rate_limits = Twitter::RateLimitChecker.new.call
    exceeded_limits = Twitter::ApplicationRateLimitFormatter.call(rate_limits)

    if exceeded_limits.any?
      message = "The following rate limits have been exceeded:\n#{exceeded_limits.join("\n")}"
      Slack::Notifier.new(Rails.application.credentials.slack[:webhook_url]).ping(message)
    end
  end
end
