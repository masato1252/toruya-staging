# https://stackoverflow.com/a/69636768/609365
Rails.application.config.after_initialize do
  require 'active_storage'

  ActiveStorage::Transformers::ImageProcessingTransformer.class_eval do
    private
    def operations
      transformations.each_with_object([]) do |(name, argument), list|
        if name.to_s == "combine_options"
          list.concat argument.keep_if { |key, value| value.present? and key.to_s != "host" }.to_a
        elsif argument.present?
          list << [ name, argument ]
        end
      end
    end
  end

  # Custom blob key generation to preserve file extensions
  ActiveStorage::Blob.class_eval do
    def key
      # We can't wait until the record is first saved to have a key for it
      return self[:key] if self[:key].present?

      # Generate base key
      base_key = self.class.generate_unique_secure_token(length: self.class::MINIMUM_TOKEN_LENGTH)

      # Add extension if filename has one
      if filename.present?
        extension = File.extname(filename.to_s)
        base_key += extension unless extension.empty?
      end

      self[:key] = base_key
    end
  end
end
