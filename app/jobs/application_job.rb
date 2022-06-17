# frozen_string_literal: true

# == Example:
#
# class DummyJob < ApplicationJob
#   debounce # default 20 seconds
#   throttle # default 20 seconds
#   debounce duration: 10 # seconds
#   throttle duration: 10 # seconds
# end
#
# DummyJob.perform_debounce(args) # only debounce rule works
# DummyJob.perform_throttle(args) # only throttle rule works
# DummyJob.perform_now # won't use any debounce or throttle rules
# DummyJob.perform_later # won't use any debounce or throttle rules
#
class ApplicationJob < ActiveJob::Base
  discard_on ActiveJob::DeserializationError

  BUFFER = 1 # second.
  DEFAULT_DELAY = 20 # seconds

  class_attribute :debounce_settings
  class_attribute :throttle_settings

  around_perform do |job, block|
    options = job.arguments.extract_options!
    throttle_enabled = options.delete(:throttle)
    debounce_enabled = options.delete(:debounce)
    job.arguments.concat(Array.wrap(options)) if options.present? # some arguments is key value format

    if throttle_settings && throttle_enabled
      cache_key = self.class.key(*job.arguments)
      expires_in = (throttle_settings[:duration] || DEFAULT_DELAY).seconds
      Rails.cache.fetch(cache_key, expires_in: expires_in) { block.call }
    elsif debounce_settings && debounce_enabled
      block.call if perform?(*job.arguments)
    else
      block.call
    end
  end

  class << self
    def debounce(*args)
      self.debounce_settings = args.extract_options!
    end

    def throttle(*args)
      self.throttle_settings = args.extract_options!
    end

    def perform_throttle(*params)
      params.push({ throttle: true })

      perform_now(*params)
    end

    def perform_debounce(*params)
      # Refresh the timestamp in redis with debounce delay added.
      delay = debounce_settings[:duration] || DEFAULT_DELAY
      Redis.current.set(key(params), now + delay)

      # Schedule the job with not only debounce delay added, but also BUFFER.
      # BUFFER helps prevent race condition between this line and the one above.
      params.push({ debounce: true })
      set(wait_until: now + delay + BUFFER).perform_later(*params)
    end

    # e.g.
    # "ElasticsearchIndexJob:gid://umami/Reservation/24242, update"
    def key(params)
      params_key = Array.wrap(params).map do |param|
        param.try(:to_global_id) || param
      end.join(", ")

      "#{self}:#{params_key}"
    end

    def now
      Time.now.to_i
    end
  end

  def perform?(*params)
    # Only the last job should come after the timestamp.
    timestamp = Redis.current.get(self.class.key(params))
    # But because of BUFFER, there could be mulitple last jobs enqueued within
    # the span of BUFFER. The first one will clear the timestamp, and the rest
    # will skip when they see that the timestamp is gone.
    return false if timestamp.nil?
    return false if Time.now.to_i < timestamp.to_i

    # Avoid race condition, only the first one del return 1, others are 0
    Redis.current.del(self.class.key(params)) == 1
  end
end
