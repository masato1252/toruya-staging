require "line/bot"

class Webhooks::LinesController < WebhooksController
  # message
  # {"events"=>
  #  [{
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
  #  }]
  # }
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
  # }
  def create
    Array.wrap(params[:events]).each do |event|
      case event[:type]
      when "message"
        message = {
          type: 'text',
          text: "hello message #{event[:message][:text]}"
        }
      when "follow"
        message = {
          type: 'text',
          text: "hello User #{event[:source][:userId]}"
        }
      end

      reply_token = params['events'][0]['replyToken']
      response = client.reply_message(reply_token, message)
    end

    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config|
        config.channel_secret = "77d954193e94cbbbe05a6a9199f96142"
        config.channel_token = "lfxphX51tf9zYFmq0G0V5FOzNS99vyNl/PFgirx0gQTbZE9nLtVL4U6DxKKyA7hAUa3awnTTjynuMbxSjbwn1A5ujuN2i1NpHB9PIGv5IaX3OA5DFga0kC7SaEhGf5nKph5HUaHuCLxKvIDdP+NOtwdB04t89/1O/w1cDnyilFU="
    }
  end
end
