# frozen_string_literal: true

class BusinessApplicationPresenter
  attr_reader :user, :h, :application

  def initialize(h, user)
    @h = h
    @user = user
    @application = user&.business_application
  end

  def approved?
    application&.approved?
  end

  def path
    case application&.state
    when "pending"
      nil
    when "approved"
      h.pay_business_path
    when "rejected"
      h.apply_business_path
    else
      h.apply_business_path
    end
  end

  def btn_text
    case application&.state
    when "pending"
      I18n.t("business.waiting_review")
    when "approved"
      I18n.t("business.pay_to_be_business_member")
    when "rejected"
      I18n.t("business.apply")
    else
      I18n.t("business.apply")
    end
  end
end
