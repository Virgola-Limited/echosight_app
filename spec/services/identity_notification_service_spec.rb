require 'rails_helper'

RSpec.describe IdentityNotificationService do
  let(:post_sender) { class_double("PostSender").as_stubbed_const }
  let(:post_sender_instance) { instance_double("PostSender") }

  before do
    allow(post_sender).to receive(:new).and_return(post_sender_instance)
    allow(post_sender_instance).to receive(:call)
  end

  describe '#run' do
    let!(:identity_with_user) { create(:identity, handle: 'with_user') }
    let!(:identity_without_user_no_data) { create(:identity, :syncable_without_user, handle: 'no_data') }
    let!(:identity_without_user_with_data) { create(:identity, :syncable_without_user, handle: 'with_data') }

    before do
      create_list(:twitter_user_metric, 14, identity: identity_without_user_with_data)
    end

    it 'does not send a message for identities with users' do
      described_class.new.run
      expect(post_sender).not_to have_received(:new).with(
        message: "Reach out to user if the public page is populated https://x.com/with_user",
        post_type: 'one_time',
        channel_type: 'slack'
      )
    end

    it 'does not send a message for identities without 14 days of data' do
      described_class.new.run
      expect(post_sender).not_to have_received(:new).with(
        message: "Reach out to user if the public page is populated https://x.com/no_data",
        post_type: 'one_time',
        channel_type: 'slack'
      )
    end

    it 'sends a message for identities without users and with 14 days of data' do
      described_class.new.run
      expect(post_sender).to have_received(:new).with(
        message: "Reach out to user if the public page is populated https://x.com/with_data",
        post_type: 'one_time',
        channel_type: 'slack'
      )
      expect(post_sender_instance).to have_received(:call)
    end
  end
end
