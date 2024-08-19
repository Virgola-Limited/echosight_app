class UserMailer < ApplicationMailer

  def users_without_subscription_email(user)
    @mail_type = 'users_without_subscription_email'
    @is_transactional_email = true
    @user = user
    mail(to: @user.email, subject: 'We Want to Hear From You!')
  end

  def send_individual_email(user, subject, body)
    @user = user
    @body_content = body.html_safe # Ensure the body content is treated as HTML
    @is_transactional_email = true

    mail(
      to: @user.email,
      subject: subject
    ) do |format|
      format.html { render layout: 'mailer' } # Render with the HTML layout
    end
  end

end
