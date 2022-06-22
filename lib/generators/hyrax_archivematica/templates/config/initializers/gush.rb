# config/initializers/gush.rb
#Gush.configure do |config|
#  config.redis_url = "redis://localhost:6379"
#  config.concurrency = 5
#  config.locking_duration = 2 # how long you want to wait for the lock to be released, in seconds
#  config.polling_interval = 0.3 # how long the polling interval should be, in seconds
#end

Gush.configure do |config|
  config.redis_url = "redis://#{ENV.fetch('REDIS_HOST', 'localhost')}:#{ENV.fetch('REDIS_PORT', '6379')}"
  config.concurrency = 1
end
