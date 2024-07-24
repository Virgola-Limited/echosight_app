require 'aws-sdk-s3'
require 'fileutils'
require 'json'
require_relative '../config/environment' # Ensure this points to your Rails environment file

class FetchImages
  def self.call
    return unless Rails.env.development?

    # Ensure required environment variables are present
    missing_env_vars = %w[
      PRODUCTION_BUCKETEER_BUCKET_NAME
      PRODUCTION_BUCKETEER_AWS_REGION
      PRODUCTION_BUCKETEER_AWS_ACCESS_KEY_ID
      PRODUCTION_BUCKETEER_AWS_SECRET_ACCESS_KEY
    ].select { |var| ENV[var].nil? }

    if missing_env_vars.any?
      puts "Missing environment variables: #{missing_env_vars.join(', ')}"
      return
    end

    # Configuration
    bucket_name = ENV['PRODUCTION_BUCKETEER_BUCKET_NAME']
    region = ENV['PRODUCTION_BUCKETEER_AWS_REGION']
    local_storage_path = Rails.root.join('public', 'uploads', 'store') # Ensure this matches the Shrine storage path
    prefix = 'store/' # Add the prefix used in S3

    # Initialize the S3 client
    s3 = Aws::S3::Client.new(
      region: region,
      access_key_id: ENV['PRODUCTION_BUCKETEER_AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['PRODUCTION_BUCKETEER_AWS_SECRET_ACCESS_KEY']
    )

    # Method to download file from S3
    def self.download_file(s3, bucket, key, local_path)
      FileUtils.mkdir_p(File.dirname(local_path))
      s3.get_object(
        response_target: local_path,
        bucket: bucket,
        key: key
      )
      puts "Successfully downloaded #{key} to #{local_path}"
    rescue Aws::S3::Errors::NoSuchKey
      puts "Key does not exist: #{key}"
    rescue => e
      puts "Error downloading file: #{e.message}"
    end

    # Fetch identities and download their images
    Identity.find_each do |identity|
      if identity.image_data
        image_data = JSON.parse(identity.image_data)
        image_key = "#{prefix}#{image_data['id']}"
        puts "Image data: #{image_data}"
        puts "Attempting to download image with key: #{image_key}"
        local_image_path = File.join(local_storage_path, image_data['id'])
        download_file(s3, bucket_name, image_key, local_image_path)
      end

      if identity.banner_data
        banner_data = JSON.parse(identity.banner_data)
        banner_key = "#{prefix}#{banner_data['id']}"
        puts "Banner data: #{banner_data}"
        puts "Attempting to download banner with key: #{banner_key}"
        local_banner_path = File.join(local_storage_path, banner_data['id'])
        download_file(s3, bucket_name, banner_key, local_banner_path)
      end
    end
  end
end

FetchImages.call