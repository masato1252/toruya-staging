# Handle Filenames and unicode chars
CarrierWave::SanitizedFile.sanitize_regexp = /[^[:word:]\.\-\+]/

s3_config_file = "aws.yml"

s3_config_path = "#{Rails.root.join('config')}/#{s3_config_file}"
s3_config = YAML.load_file(s3_config_path)[Rails.env].symbolize_keys

if Rails.env.test?
  CarrierWave.configure do |config|
    config.storage = :file
  end
else
  CarrierWave.configure do |config|
    config.fog_provider = 'fog/aws'
    config.fog_credentials = {
      :provider => 'AWS',
      :aws_access_key_id      => ENV['AWS_ACCESS_KEY_ID'],
      :aws_secret_access_key  => ENV['AWS_SECRET_ACCESS_KEY'],
      :region => s3_config[:region]
    }
    config.fog_directory  = s3_config[:bucket_name]
    config.fog_public     = false
    config.fog_attributes = { cache_control: "public, max-age=#{7.days.to_i}" }
    config.fog_authenticated_url_expiration = 7.days.to_i # seconds
  end
end
