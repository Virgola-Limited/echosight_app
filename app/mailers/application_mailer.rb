class ApplicationMailer < ActionMailer::Base
  default template_path: 'mailers'

  default from: "noreply@echosight.com"
  layout "mailer"

end
