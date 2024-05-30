# frozen_string_literal: true

# == Schema Information
#
# Table name: users
#
#  id                           :bigint           not null, primary key
#  confirmation_sent_at         :datetime
#  confirmation_token           :string
#  confirmed_at                 :datetime
#  current_sign_in_at           :datetime
#  current_sign_in_ip           :string
#  email                        :string           default(""), not null
#  enabled_without_subscription :boolean          default(FALSE)
#  encrypted_password           :string           default(""), not null
#  failed_attempts              :integer          default(0), not null
#  invitation_accepted_at       :datetime
#  invitation_created_at        :datetime
#  invitation_limit             :integer
#  invitation_sent_at           :datetime
#  invitation_token             :string
#  invitations_count            :integer          default(0)
#  invited_by_type              :string
#  last_name                    :string
#  last_sign_in_at              :datetime
#  last_sign_in_ip              :string
#  locked_at                    :datetime
#  name                         :string
#  remember_created_at          :datetime
#  reset_password_sent_at       :datetime
#  reset_password_token         :string
#  sign_in_count                :integer          default(0), not null
#  unconfirmed_email            :string
#  unlock_token                 :string
#  vip_since                    :date
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  invited_by_id                :bigint
#  stripe_customer_id           :string
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_invitation_token      (invitation_token) UNIQUE
#  index_users_on_invited_by            (invited_by_type,invited_by_id)
#  index_users_on_invited_by_id         (invited_by_id)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_stripe_customer_id    (stripe_customer_id)
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password' }
    confirmed_at { Time.now } # Set the confirmed_at attribute to the current time

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :with_identity do
      association :identity
    end

    trait :with_subscription do
      after(:create) do |user|
        create(:subscription, user:)
      end
    end
  end
end
