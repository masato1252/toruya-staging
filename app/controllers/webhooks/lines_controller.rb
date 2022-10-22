# frozen_string_literal: true

require "line/bot"

class Webhooks::LinesController < WebhooksController
  before_action :verify_header

  # message
  # {"events"=>[
  #  {
  #    "type"=>"message", 
  #    "replyToken"=>"49f33fecfd2a4978b806b7afa5163685", 
  #    "source"=>{
  #      "userId"=>"Ua52b39df3279673c4856ed5f852c81d9",
  #      "type"=>"user"
  #    },
  #    "timestamp"=>1536052545913, 
  #    "message"=>{
  #      "type"=>"text", 
  #      "id"=>"8521501055275", 
  #      "text"=>"??"
  #    }
  #  }
  # },
  #
  # {
  #   "replyToken": "nHuyWiB7yP5Zw52FIkcQobQuGDXCTA",
  #   "type": "follow",
  #   "mode": "active",
  #   "timestamp": 1462629479859,
  #   "source": {
  #     "type": "user",
  #     "userId": "U4af4980629..."
  #   }
  # }]
  def create
    Array.wrap(params[:events]).each do |event|
      Lines::HandleEvent.run(social_account: social_account, event: event.permit!.to_h)
    end

    head :ok
  end

  private

  def social_account
    @social_account ||= SocialAccount.find_by!(channel_id: params[:channel_id])
  end

  def verify_header
    channel_secret = social_account.channel_secret # Channel secret string
    http_request_body = request.raw_post # Request body string
    hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, channel_secret, http_request_body)
    signature = Base64.strict_encode64(hash)

    # Compare X-Line-Signature request header string and the signature
    if signature != request.headers["X-Line-Signature"]
      Rollbar.warning("Unexpected request", request: http_request_body)
    end
  end
end
