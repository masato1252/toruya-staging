module MailerMethods
  protected
  def named_email(user)
    "#{user.name} <#{user.email}>"
  end

  def subject(subject)
    "[Toruya] #{subject}"
  end

  def mail(*args)
    if locale = args.first[:locale]
      I18n.with_locale(locale) do
        super(*args) do |format|
          format.text do
            if locale == :ja
              render action_name
            else
              render "#{action_name}_#{locale}", layout: "mailer_#{locale}"
            end
          end
        end
      end
    else
      super
    end
  end
end
