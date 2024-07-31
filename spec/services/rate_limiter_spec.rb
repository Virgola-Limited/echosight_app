# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RateLimiter do
  let(:rate) { 5 }
  let(:per) { 2 } # 2 seconds
  let(:warning_threshold) { 0.8 }
  let(:cooldown) { 2 } # 2 seconds
  let(:rate_limiter) { described_class.new(rate: rate, per: per, warning_threshold: warning_threshold, cooldown: cooldown) }

  describe '#throttle' do
    it 'allows requests within the rate limit' do
      expect { rate.times { rate_limiter.throttle } }.not_to raise_error
    end

    it 'waits for the next request when rate limit is exceeded' do
      start_time = Time.now
      (rate + 1).times { rate_limiter.throttle }
      end_time = Time.now

      elapsed_time = end_time - start_time
      expect(elapsed_time).to be >= (per.to_f / rate)
    end

    it 'sends a warning when the rate exceeds the threshold' do
      allow(Notifications::SlackNotifier).to receive(:call)

      # Directly manipulate the tokens to below the threshold
      rate_limiter.instance_variable_set(:@tokens, rate * (1 - warning_threshold) - 1)
      rate_limiter.throttle

      expect(Notifications::SlackNotifier).to have_received(:call).with(hash_including(message: /The SocialData API has used more than/)).once
    end

    it 'does not send multiple warnings within the cooldown period' do
      allow(Notifications::SlackNotifier).to receive(:call)

      # Directly manipulate the tokens to below the threshold
      rate_limiter.instance_variable_set(:@tokens, rate * (1 - warning_threshold) - 1)
      rate_limiter.throttle
      rate_limiter.throttle # Attempt to trigger another warning within cooldown

      expect(Notifications::SlackNotifier).to have_received(:call).once
    end
  end
end
