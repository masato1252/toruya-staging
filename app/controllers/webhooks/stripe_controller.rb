class Webhooks::StripeController < WebhooksController
  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, Rails.application.secrets.stripe_webhook_secret
      )
    rescue JSON::ParserError => e
      # Invalid payload
      status 400
      return
    rescue Stripe::SignatureVerificationError => e
      # Invalid signature
      status 400
      return
    end

    outcome = StripeEvents::Handler.run(event: event)

    if outcome.valid?
      head :ok
    else
      Rollbar.error("WebHook stripe error", {
        event: event,
        errors: outcome.errors.details
      })
      head :bad_request
    end
  end
end
