require 'mailer_methods'

class NotificationMailer < ActionMailer::Base
  default from: "Toruya <toruya.services@gmail.com>"

  include MailerMethods

  layout 'mailer'

  def customers_import_finished(contact_group)
    @contact_group = contact_group

    mail(:to => contact_group.user.email,
         :subject => subject("Contact Import already finisehd"))

  end
end
