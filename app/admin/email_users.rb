ActiveAdmin.register_page 'Email Users' do
  page_action :send_emails, method: :post do
    users = []

    case params[:email_type]
    when 'all_users'
      users = User.all
      Rails.logger.info "Selected all users"
    when 'without_subscription'
      users = User.without_subscription
      Rails.logger.info "Selected users without subscription"
    when 'with_subscription'
      users = User.with_subscription
      Rails.logger.info "Selected users with subscription (not trialling)"
    when 'with_trial_subscription'
      users = User.with_trial_subscription
    when 'without_identity'
      users = User.without_identity
      Rails.logger.info "Selected users without identity"
    end

    if users.any?
      users.each do |user|
        UserMailer.send_individual_email(user, params[:subject], params[:body]).deliver_now
        Rails.logger.info "Sent email to #{user.email}"
      end
      redirect_to admin_email_users_path, notice: "Emails sent to selected group."
    else
      redirect_to admin_email_users_path, alert: "No users found for the selected group."
    end
  end

  content do
    form action: admin_email_users_send_emails_path, method: :post do
      # CSRF Token
      input type: 'hidden', name: 'authenticity_token', value: form_authenticity_token

      div do
        label "Email Subject"
        br
        input name: 'subject', type: 'text', required: true, style: 'width: 100%;'
      end

      div do
        label "Email Body"
        br
        textarea name: 'body', required: true, style: 'width: 100%; height: 300px;'
      end

      div do
        label "Select User Group"
        br
        select name: 'email_type', required: true, style: 'width: 100%;' do
          option value: 'all_users' do
            "All Users"
          end
          option value: 'without_subscription' do
            "Users without Subscription"
          end
          option value: 'with_subscription' do
            "Users with Subscription"
          end
          option value: 'with_trial_subscription' do
            "Users with Trial Subscription"
          end
          option value: 'without_identity' do
            "Users without Identity"
          end
        end
      end

      div do
        input type: 'submit', value: 'Send Email', class: 'button primary'
      end
    end
  end
end
