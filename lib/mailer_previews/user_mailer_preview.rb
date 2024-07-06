# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/feedback_request
  def feedback_request
    UserMailer.feedback_request(User.first)
  end
end
