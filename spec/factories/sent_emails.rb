FactoryBot.define do
  factory :sent_email do
    association :user
    recipient { user.email }
    subject { 'We Want to Hear From You!' }
    body { 'Test body content' }
    tracking_id { SecureRandom.uuid }
    email_type { 'users_without_subscription_email' }
    # add other attributes as necessary
  end
end
