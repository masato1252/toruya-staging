module LlamaIndex
  module Ai
    def self.build(user_id:, urls:)
      AI_BUILD.perform(user_id, urls)
    end

    def self.query(user_id:, question:)
      response = AI_QUERY.perform(user_id, question)

      {
        message: response.to_s,
        references: response.metadata.to_h.values.map {|h| h['Source'] }.uniq
      }
    end
  end
end
