module MailerMethods
  protected
  def named_email(user)
    "#{user.name} <#{user.email}>"
  end

  def subject(subject)
    "[Toruya] #{subject}"
  end

  def mail(*args)
    I18n.with_locale(I18n.default_locale) do
      super
    end
  end
end
