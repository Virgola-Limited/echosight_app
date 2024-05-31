# == Schema Information
#
# Table name: subscriptions
#
#  id                     :bigint           not null, primary key
#  active                 :boolean          default(TRUE)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  stripe_price_id        :string
#  stripe_subscription_id :string
#  user_id                :bigint           not null
#
# Indexes
#
#  index_subscriptions_on_stripe_price_id         (stripe_price_id)
#  index_subscriptions_on_stripe_subscription_id  (stripe_subscription_id)
#  index_subscriptions_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Subscription < ApplicationRecord
  belongs_to :user

  validate :only_one_active_subscription, on: :create
  validates :stripe_subscription_id, presence: true, uniqueness: true
  validates :stripe_price_id, presence: true

  scope :active, -> { where(active: true) }

  # ActiveRecord::Base.transaction do
  #   user.subscriptions.active.update_all(active: false) # Deactivate all active subscriptions
  #   user.subscriptions.create!(new_subscription_params) # Create and activate the new subscription
  # end

  # You can define a method to check if the subscription is still active in Stripe
  # def subscription_active?
  #   stripe_subscription = Stripe::Subscription.retrieve(self.stripe_subscription_id)
  #   stripe_subscription.status == 'active' && !stripe_subscription.cancel_at_period_end
  # end

  # Method to check for the Stripe subscription's current phase (trial, active, etc.)
  # def current_phase
  #   stripe_subscription = Stripe::Subscription.retrieve(self.stripe_subscription_id)
  #   return 'trial' if stripe_subscription.trial_end.present? && Time.at(stripe_subscription.trial_end) > Time.now
  #   return 'active' if stripe_subscription.status == 'active'
  #   'inactive'
  # end

  def self.ransackable_associations(auth_object = nil)
    ["user"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["active", "created_at", "id", "stripe_price_id", "stripe_subscription_id", "updated_at", "user_id"]
  end

  def self.trial_period
    ENV.fetch('TRIAL_PERIOD_DAYS', 0)
  end

  private

  def only_one_active_subscription
    if user.subscriptions.active.exists?
      errors.add(:user, 'can only have one active subscription')
    end
  end
end
