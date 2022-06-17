require "redis_storage"

RedisStorage.connect_to_redis!

begin
  Redis.current.ping
rescue
  puts "warring: No redis server! Please install and start redis, install on MacOSX: 'sudo brew install redis', start : 'redis-server'"
end
