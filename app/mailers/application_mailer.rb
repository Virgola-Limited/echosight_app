class ApplicationMailer < ActionMailer::Base
  default template_path: 'mailers'

  default from: "x@echosight.io"
  layout "mailer"

end
