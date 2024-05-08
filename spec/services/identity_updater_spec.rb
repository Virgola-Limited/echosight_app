require 'rails_helper'

RSpec.describe IdentityUpdater do
  describe '#call' do
    let!(:identity) { create(:identity, :loftwah, :with_oauth_credential) }
    let(:user_data) do
      {
        'id' => '1192091185',
        'username' => identity.handle,
        'public_metrics' => {
          'followers_count' => 6676,
          'following_count' => 4554,
          'listed_count' => 42,
          'tweet_count' => 52729
        },
        'image_url' => 'https://pbs.twimg.com/profile_images/1756873036220059648/zc13kjbX_normal.jpg',
        'banner_url' => 'https://pbs.twimg.com/profile_banners/1691930809756991488/1710884709',
        'description' => 'Revolutionize Your Twitter/X Strategy with Echosight https://t.co/uZpeIYc5Nq'
      }
    end
    let(:expected_description) { "Revolutionize Your Twitter/X Strategy with Echosight https://echosight.io/" }
    let(:updater) { described_class.new(user_data) }

    context 'when the 400x400 image exists' do
      let(:expected_image_url) { user_data['image_url'].gsub('_normal', '_400x400') }
      let(:expected_banner_url) { "#{user_data['banner_url']}/1500x500" }

      it 'updates the user images and banner only if different from existing ones' do
        VCR.use_cassette('IdentityUpdater') do
          # Simulate image uploads
          identity.image = URI.open(expected_image_url)
          identity.banner = URI.open(expected_banner_url)
          identity.save!

          # Validate image metadata
          expect(identity.image.metadata['width']).to eq(400)
          expect(identity.image.metadata['height']).to eq(400)

          # Validate banner metadata
          expect(identity.banner.metadata['width']).to eq(1500)

          # Ensure description is as expected
          expect(identity.description).to eq('Twitter user bio')

          updater.call
          identity.reload

          # Validate the image and banner properties remain unchanged
          expect(identity.image.metadata['width']).to eq(400)
          expect(identity.image.metadata['height']).to eq(400)
          expect(identity.banner.metadata['width']).to eq(1500)

          # Ensure other fields are updated correctly
          expect(identity.description).to eq(expected_description)
        end
      end
    end
  end
end
