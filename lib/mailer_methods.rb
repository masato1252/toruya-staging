# frozen_string_literal: true

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
          layout = args.first[:layout] || self.class._layout

          format.text do
            if locale == :ja
              render action_name, layout: layout
            else
              render "#{action_name}_#{locale}", layout: layout ? "#{layout}_#{locale}" : false
            end
          end
        end
      end
    else
      super
    end
  end
end
