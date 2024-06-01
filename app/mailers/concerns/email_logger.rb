# app/mailers/concerns/email_logger.rb
module EmailLogger
  extend ActiveSupport::Concern

  included do
    after_action :log_sent_email
  end

  private

  def log_sent_email
    return unless mail.perform_deliveries

    tracking_id = SecureRandom.uuid

    # Extract the recipient, subject, and body from the mail object
    recipient = mail.to.join(', ')
    subject = mail.subject
    body = mail.body.encoded

    # Find the user by email
    user = User.find_by(email: recipient)

    # Create the SentEmail record
    SentEmail.create!(
      recipient: recipient,
      subject: subject,
      body: body,
      tracking_id: tracking_id,
      email_type: @mail_type || 'default',
      user_id: user&.id
    )

    # Add the tracking pixel to the body
    mail.body = "#{body} <img src='#{Rails.application.credentials.dig(:host)}/track/open/#{tracking_id}' style='display:none'/>"
  end
end
