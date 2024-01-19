class ApplicationMailer < ActionMailer::Base
  default template_path: 'mailers'

  default from: "chris@echosight.io"
  layout "mailer"

end
