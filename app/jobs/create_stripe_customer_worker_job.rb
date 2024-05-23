class CreateStripeCustomerWorkerJob
  include Sidekiq::Job

  def perform(user_id)
    user = User.find_by(id: user_id)
    return if user.nil? || user.stripe_customer_id.present?

    begin
      customer = Stripe::Customer.create(email: user.email)
      user.update!(stripe_customer_id: customer.id)
    end
  end
end
