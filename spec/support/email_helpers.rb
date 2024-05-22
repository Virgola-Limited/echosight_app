# spec/support/email_helpers.rb
module EmailHelpers
  def expect_transactional_email(email = nil)
    email = ActionMailer::Base.deliveries.last if email.nil?
    expect(email.body.encoded).to include("This is a transactional email related to your account or subscription. You cannot unsubscribe from these emails.")
  end
end
