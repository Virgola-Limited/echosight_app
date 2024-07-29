# == Schema Information
#
# Table name: subscriptions
#
#  id                     :bigint           not null, primary key
#  active                 :boolean          default(TRUE)
#  current_period_end     :datetime
#  status                 :string
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
  validates :user, presence: true

  scope :active, -> { where(active: true) }

  after_save :notify_status_change, if: :saved_change_to_active?

  def self.ransackable_associations(auth_object = nil)
    ["user"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["active", "created_at", "id", "stripe_price_id", "stripe_subscription_id", "updated_at", "user_id", "status", "current_period_end"]
  end

  def self.trial_period
    ENV.fetch('TRIAL_PERIOD_DAYS', 0)
  end

  private

  def notify_status_change
    message = "Subscription #{stripe_subscription_id} for user #{user.email} is now #{active? ? 'active' : 'inactive'}."
    Notifications::SlackNotifier.call(
      message: message
    )
  end

  def only_one_active_subscription
    if user.subscriptions.active.exists?
      errors.add(:user, 'can only have one active subscription')
    end
  end
end
