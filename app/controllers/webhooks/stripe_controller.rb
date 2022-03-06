class Webhooks::StripeController < WebhooksController
  def create
    payload = request.body.read
    data = JSON.parse(payload, symbolize_names: true)
    event = Stripe::Event.construct_from(data)

    outcome = StripeEvents::Handler.run(event: event)

    if outcome.valid?
      head :ok
    else
      head :bad_request
    end
  end
end
