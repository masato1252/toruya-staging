class KeyValueStorage
  class << self
    def set(key, value)
      store.set(key, value)
    end

    def get(key)
      store.get(key)
    end

    def del(key)
      store.del(key)
    end

    def store
      $redis
    end
  end
end

