class WithdrawalMailer < ApplicationMailer
  def monthly_report
    @withdrawal = params[:withdrawal]
    @user = @withdrawal.receiver

    mail(
      to: @user.email,
      subject: subject(I18n.t("withdrawal_mailer.monthly_report.title")),
      locale: I18n.default_locale
    )
  end

  private

  def user
    @user ||= params[:user]
  end
end
