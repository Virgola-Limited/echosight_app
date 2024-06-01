# app/models/sent_email.rb
class SentEmail < ApplicationRecord
  validates :recipient, :subject, :body, :tracking_id, :email_type, presence: true
end