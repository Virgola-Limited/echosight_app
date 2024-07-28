class RateLimiter
  def initialize(rate: 100, per: 60)
    @rate = rate
    @per = per
    @tokens = rate
    @last_checked = Time.now
    @mutex = Mutex.new
  end

  def throttle
    @mutex.synchronize do
      now = Time.now
      elapsed = now - @last_checked
      @tokens += elapsed * (@rate.to_f / @per)
      @tokens = [@tokens, @rate].min
      @last_checked = now

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
end