# spec/services/post_sender_spec.rb
require 'rails_helper'

RSpec.describe PostSender, type: :service do
  let(:message) { "Congratulations @loftwah on topping the leaderboard on Echosight!" }
  let(:post_type) { "once_a_week" }
  let(:channel_type) { "slack" }
  let!(:user) { create(:user) }
  let(:image_url) { nil }

  describe '#call' do
    context 'when the message is valid and not a duplicate' do
      it 'creates a new SentPost and sends the message' do
        expect(Notifications::SlackNotifier).to receive(:call).with(message: message, channel: :general)

        expect {
          PostSender.new(message: message, post_type: post_type, channel_type: channel_type, user: user, image_url: image_url).call
        }.to change(SentPost, :count).by(1)
      end
    end

    context 'when the message exceeds the allowed length' do
      let(:message) { "a" * 300 }

      it 'does not create a SentPost and sends a failure notification' do
        expect(PostMailer).to receive(:post_failed_email).and_call_original

        expect {
          PostSender.new(message: message, post_type: post_type, channel_type: channel_type, user: user, image_url: image_url).call
        }.not_to change(SentPost, :count)
      end
    end

    context 'when the message is a duplicate' do
      before do
        create(:sent_post, message: message, post_type: post_type, channel_type: channel_type, sent_at: 2.days.ago)
      end

      it 'does not create a SentPost and sends a failure notification' do
        expect(PostMailer).to receive(:post_failed_email).and_call_original

        expect {
          PostSender.new(message: message, post_type: post_type, channel_type: channel_type, user: user, image_url: image_url).call
        }.not_to change(SentPost, :count)
      end
    end

    context 'when a once_a_week message is sent more than once a week' do
      before do
        create(:sent_post, message: message, post_type: post_type, channel_type: channel_type, sent_at: 3.days.ago)
      end

      it 'does not create a SentPost and sends a failure notification' do
        expect(PostMailer).to receive(:post_failed_email).and_call_original

        expect {
          PostSender.new(message: message, post_type: post_type, channel_type: channel_type, user: user, image_url: image_url).call
        }.not_to change(SentPost, :count)
      end
    end

    context 'when a once_a_week message is sent after a week' do
      before do
        create(:sent_post, message: message, post_type: post_type, channel_type: channel_type, sent_at: 9.days.ago)
      end

      it 'creates a new SentPost and sends the message' do
        expect(Notifications::SlackNotifier).to receive(:call).with(message: message, channel: :general)

        expect {
          PostSender.new(message: message, post_type: post_type, channel_type: channel_type, user: user, image_url: image_url).call
        }.to change(SentPost, :count).by(1)
      end
    end

    xcontext 'when sending a Twitter post' do
      let(:channel_type) { "twitter" }
      let(:image_url) { "http://example.com/image.jpg" }

      it 'calls Twitter::PostService' do
        expect_any_instance_of(Twitter::PostService).to receive(:call).and_return(true)

        PostSender.new(message: message, post_type: post_type, channel_type: channel_type, user: user, image_url: image_url).call
      end

      it 'sends a failure notification if Twitter::PostService fails' do
        allow_any_instance_of(Twitter::PostService).to receive(:call).and_return(nil)
        expect(PostMailer).to receive(:post_failed_email).and_call_original

        PostSender.new(message: message, post_type: post_type, channel_type: channel_type, user: user, image_url: image_url).call
      end
    end
  end
end
