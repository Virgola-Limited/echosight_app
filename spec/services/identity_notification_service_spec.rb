require 'rails_helper'

RSpec.describe IdentityNotificationService do
  let(:post_sender) { class_double("PostSender").as_stubbed_const }
  let(:post_sender_instance) { instance_double("PostSender") }

  before do
    allow(post_sender).to receive(:new).and_return(post_sender_instance)
    allow(post_sender_instance).to receive(:call)
  end

  describe '#run' do
    context 'when the identity has users' do
      let!(:identity_with_user) { create(:identity, handle: 'with_user') }

      it 'does not send a message for identities with users' do
        described_class.new.run
        expect(post_sender).not_to have_received(:new)
      end
    end

    context 'when the identity does not have users' do
      context 'when the identity has 14 days of data' do
        let!(:identity_without_user_with_data) { create(:identity, :syncable_without_user, handle: 'with_data') }
        let!(:twitter_user_metrics) { create_list(:twitter_user_metric, 14, identity: identity_without_user_with_data) }

        it 'sends a message for identities without users and with 14 days of data' do
          described_class.new.run
          expect(post_sender).to have_received(:new).with(
            a_hash_including(
              message: a_string_including("Reach out to user if the public page is populated"),
              post_type: 'one_time',
              channel_type: 'slack'
            )
          )
          expect(post_sender_instance).to have_received(:call)
        end
      end

      context 'when the identity does not have 14 days of data' do
        let!(:identity_without_user_no_data) { create(:identity, :syncable_without_user, handle: 'no_data') }

        it 'does not send a message for identities without 14 days of data' do
          described_class.new.run
          expect(post_sender).not_to have_received(:new).with(
            a_hash_including(
              message: a_string_including("Reach out to user if the public page is populated"),
              post_type: 'one_time',
              channel_type: 'slack'
            )
          )
        end
      end
    end
  end
end
