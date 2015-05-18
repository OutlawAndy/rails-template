
if Rails.env.test?
  CarrierWave.configure do |config|
    config.storage = :file
    config.enable_processing = false
  end
else
  CarrierWave.configure do |config|

    config.storage = :fog
    config.root = Rails.root.join('tmp')
    config.cache_dir = 'carrierwave'
    config.fog_credentials = {
      provider: 'AWS',
      aws_access_key_id: ENV["AWS_S3_ACCESS_KEY_ID"],
      aws_secret_access_key: ENV["AWS_S3_SECRET_ACCESS_KEY"],
    }
    config.fog_directory = ENV["AWS_S3_BUCKET"]
  end
end