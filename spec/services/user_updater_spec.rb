require 'rails_helper'

RSpec.describe UserUpdater, :vcr do
  describe '#call' do
    let!(:identity) { create(:identity, :loftwah, :with_oauth_credential) }
    let(:user_data) do
      {
        "id" => "1192091185",
        "username" => identity.handle,
        "public_metrics" => {
          "followers_count" => 6676,
          "following_count" => 4554,
          "listed_count" => 42,
          "tweet_count" => 52729
        },
        "image_url" => image_url,
        "banner_url" => "https://pbs.twimg.com/profile_banners/1192091185/1707817030"
      }
    end
    let(:updater) { described_class.new(user_data) }
    let(:image_url) { 'https://pbs.twimg.com/profile_images/1756873036220059648/zc13kjbX_normal.jpg' }

    context 'when the 400x400 image exists' do
      let(:expected_image_url) { user_data["image_url"].gsub('_normal', '_400x400') }

      it 'updates the user images with transformed URL' do
        expect(identity.banner_url).to be_nil
        expect { updater.call }.to change { identity.reload.image_url }.from(nil).to(expected_image_url)
        expect(identity.banner_url).to eq(user_data["banner_url"])
      end
    end

    context 'when the 400x400 image does not exist' do
      it 'update the user image with the original URL' do
        expect(identity.banner_url).to be_nil
        expect { updater.call }.to change { identity.reload.image_url }.from(nil).to(image_url)
        expect(identity.banner_url).to eq(user_data["banner_url"])
      end
    end
  end
end
