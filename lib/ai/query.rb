module Ai
  module Query
    def self.query(question)
      response = AI_QUERY.query(question)

      {
        message: response.to_s,
        references: response.metadata.to_h.values.map {|h| h['Source'] }.uniq
      }
    end
  end
end
