require 'rails_helper'

RSpec.describe 'Active Admin navigation links' do
  let(:admin_user) { create(:admin_user) }

  before do
    login_as admin_user, scope: :admin_user
    identity = create(:identity, :syncable_without_user)
    create(:tweet, identity: identity)
    create_list(:tweet_metric, 2, tweet: Tweet.last)
    visit admin_root_path
    Bullet.raise = false
  end

  after { Bullet.raise = true }

  def links
    all('#tabs .menu_item a').map { |link| [link[:href], link.text.strip] }.reject { |href, text| text == 'PgHero' || text == 'Sidekiq' }
  end

  def create_factory_for(link_text)
    factory_name = link_text.underscore.singularize.to_sym
    factory_name = create(factory_name) if FactoryBot.factories.registered?(factory_name)
  rescue => e
    Rails.logger.warn("Factory creation failed for #{factory_name}: #{e.message}")
  end

  it 'loads all top menu links without errors' do
    expect(links.count).to be > 5

    links.each do |href, text|
      create_factory_for(text)
      visit href
      expect(page).not_to have_content('404'), "Expected no '404' error for link: #{href}"
      expect(page).not_to have_content('500'), "Expected no '500' error for link: #{href}"
    end
  end

  it 'redirects to login page if not logged in' do
    logout(:admin_user)

    links.each do |href, _text|
      visit href
      expect(current_path).to eq(new_admin_user_session_path), "Expected to be redirected to login page for link: #{href}"
    end
  end
end
