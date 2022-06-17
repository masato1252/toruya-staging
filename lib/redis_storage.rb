class RedisStorage
  class << self
    def connect_to_redis!
      Redis.current = create_client
    end

    private

    def create_client
      Redis.new(url: Rails.application.config_for('redis')['server'])
    end
  end
end

