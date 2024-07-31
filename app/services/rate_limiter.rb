class RateLimiter
  def initialize(rate: 120, per: 60, warning_threshold: 0.8, cooldown: 600)
    @rate = rate
    @per = per
    @tokens = rate
    @last_checked = Time.now
    @mutex = Mutex.new
    @warning_threshold = warning_threshold
    @cooldown = cooldown
    @last_warning = Time.now - cooldown
  end

  def throttle
    @mutex.synchronize do
      now = Time.now
      elapsed = now - @last_checked
      @tokens += elapsed * (@rate.to_f / @per)
      @tokens = [@tokens, @rate].min
      @last_checked = now

      # puts "Tokens: #{@tokens}, Elapsed: #{elapsed}" # Debug logging

      if @tokens < (@rate * (1 - @warning_threshold))
        send_warning(now) if now - @last_warning >= @cooldown
      end

      if @tokens >= 1
        @tokens -= 1
        return
      else
        sleep_time = (@per.to_f / @rate) - elapsed
        sleep(sleep_time) if sleep_time > 0
        @tokens -= 1
      end
    end
  end

  private

  def send_warning(now)
    @last_warning = now
    message = "The SocialData API has used more than #{@rate * (1 - @warning_threshold)} requests per minute"
    Notifications::SlackNotifier.call(message: message, channel: :errors)
  end
end
