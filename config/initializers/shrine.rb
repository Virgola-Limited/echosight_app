require "shrine"
require "shrine/storage/file_system"
require 'shrine/storage/s3'
require 'shrine/plugins/store_dimensions'

if Rails.application.credentials.dig(:digital_ocean_spaces, :access_key_id).present? &&
   Rails.application.credentials.dig(:digital_ocean_spaces, :secret_access_key).present?

  s3_options = Rails.application.credentials.digital_ocean_spaces.symbolize_keys

  Shrine.storages = {
    cache: Shrine::Storage::S3.new(
      prefix: 'cache',
      public: true,
      **s3_options
    ),
    store: Shrine::Storage::S3.new(
      prefix: 'store',
      public: true,
      **s3_options
    ),
  }

  Shrine.plugin :url_options, store: {
    host: "https://#{s3_options[:bucket]}.#{s3_options[:region]}.digitaloceanspaces.com"
  }
else
  Shrine.storages = {
    cache: Shrine::Storage::FileSystem.new('public', prefix: 'uploads/cache'),
    store: Shrine::Storage::FileSystem.new('public', prefix: 'uploads/store'),
  }
end

Shrine.plugin :activerecord
Shrine.plugin :store_dimensions
Shrine.plugin :cached_attachment_data
Shrine.plugin :restore_cached_data
Shrine.plugin :determine_mime_type
# Shrine.plugin :derivation_endpoint, secret_key: Rails.application.credentials.secret_key_base