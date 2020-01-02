class BusinessApplicationPresenter
  attr_reader :user, :h, :application

  def initialize(h, user)
    @h = h
    @user = user
    @application = user.business_application
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
      "Waiting review"
    when "approved"
      "Pay to be business member"
    when "rejected"
      "Apply"
    else
      "Apply"
    end
  end
end
