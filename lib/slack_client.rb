class SlackClient
  include Singleton

  def initialize
    @client = Slack::Web::Client.new
  end


  def send(*args)
    @client.chat_postMessage(*args)
  end

  def self.send(*args)
    instance.send(*args)
  end
end
