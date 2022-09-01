module FlowBacktracer
  def self.enable(namespace)
    RequestStore.store[namespace] = ActiveSupport::OrderedHash.new
  end

  def self.enabled?(namespace)
    !RequestStore.store[namespace].nil?
  end

  def self.track(namespace, &block)
    if enabled?(namespace)
      variables = block.call

      key = variables.keys.first
      # Merge the same key variables
      if RequestStore.store[namespace].key?(key)
        case RequestStore.store[namespace][key]
        when Hash
          RequestStore.store[namespace][key].merge!(variables[key])
        when Array
          RequestStore.store[namespace][key] = (RequestStore.store[namespace][key] + variables[key]).uniq
        else
          RequestStore.store[namespace].merge!(variables)
        end
      else
        RequestStore.store[namespace].merge!(variables)
      end
    end
  end

  def self.backtrace(namespace)
    RequestStore.store[namespace].to_a
  end
end
