# frozen_string_literal: true

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port        ENV.fetch("PORT") { 4321 }

# SSL Configuration for development
if ENV['RAILS_ENV'] == 'development' && File.exist?('config/ssl/localhost.pem')
  ssl_bind '0.0.0.0', '4322', {
    key: 'config/ssl/localhost-key.pem',
    cert: 'config/ssl/localhost.pem',
    verify_mode: 'none'
  }
end

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
# Note: Workers are disabled in development due to macOS fork() issues with Objective-C runtime
workers ENV.fetch("WEB_CONCURRENCY") { ENV['RAILS_ENV'] == 'development' ? 0 : 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app! if ENV.fetch("WEB_CONCURRENCY", ENV['RAILS_ENV'] == 'development' ? 0 : 2).to_i > 0

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
require 'barnes'

before_fork do
  # worker specific setup

  Barnes.start # Must have enabled worker mode for this to block to be called
end
