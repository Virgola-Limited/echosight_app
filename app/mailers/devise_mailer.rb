class DeviseMailer < Devise::Mailer
  include EmailLogger

  layout 'mailer'

  before_action :set_email_type

  private

  def set_email_type
    @is_transactional_email = true
  end
end
