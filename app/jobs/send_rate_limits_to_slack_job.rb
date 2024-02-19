class SendRateLimitsToSlackJob
  include Sidekiq::Job

  def perform
    rate_limits = Twitter::RateLimitChecker.new.call
    exceeded_limits = Twitter::ApplicationRateLimitFormatter.call(rate_limits)

    if exceeded_limits.any?
      message = "The following rate limits have been exceeded:\n#{exceeded_limits.join("\n")}"
      Notifications::SlackNotifier.call(message)
    end
  end
end
