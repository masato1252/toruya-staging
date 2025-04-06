class SocialMessages::CreateEmail < ActiveInteraction::Base
  object :customer
  string :email
  string :message
  string :subject

  def execute
    SocialMessage.create!(
      social_account: customer.social_customer&.social_account,
      social_customer: customer.social_customer,
      customer_id: customer.id,
      user_id: customer.user_id,
      raw_content: message,
      content_type: "text",
      readed_at: Time.current,
      sent_at: Time.current,
      message_type: "bot",
      channel: SocialMessage.channels[:email]
    )

    CustomerMailer.with(
      customer: customer,
      email: email,
      message: message,
      subject: subject
    ).custom.deliver_now
  end
end