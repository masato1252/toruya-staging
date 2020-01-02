class AdminMailer < ApplicationMailer
  ADMIN_EMAIL = "haruko_liu@dreamhint.com"
  layout false

  def new_business_application
    mail(
      to: ADMIN_EMAIL,
      subject: subject("New business member application"),
      locale: I18n.default_locale
    )
  end
end
