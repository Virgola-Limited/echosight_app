# require 'aws-sdk-s3'
# require 'fileutils'
# require 'json'
# require_relative '../config/environment' # Ensure this points to your Rails environment file

# # Configuration
# BUCKET_NAME = ENV['PRODUCTION_BUCKETEER_BUCKET_NAME']
# REGION = ENV['PRODUCTION_BUCKETEER_AWS_REGION']
# LOCAL_STORAGE_PATH = Rails.root.join('public', 'uploads', 'store') # Ensure this matches the Shrine storage path
# PREFIX = 'store/' # Add the prefix used in S3

# # Initialize the S3 client
# s3 = Aws::S3::Client.new(
#   region: REGION,
#   access_key_id: ENV['PRODUCTION_BUCKETEER_AWS_ACCESS_KEY_ID'],
#   secret_access_key: ENV['PRODUCTION_BUCKETEER_AWS_SECRET_ACCESS_KEY']
# )

# # Method to download file from S3
# def download_file(s3, bucket, key, local_path)
#   FileUtils.mkdir_p(File.dirname(local_path))
#   s3.get_object(
#     response_target: local_path,
#     bucket: bucket,
#     key: key
#   )
# rescue Aws::S3::Errors::NoSuchKey
#   puts "Key does not exist: #{key}"
# rescue => e
#   puts "Error downloading file: #{e.message}"
# end

# # Method to download file from S3
# def download_file(s3, bucket, key, local_path)
#   FileUtils.mkdir_p(File.dirname(local_path))
#   s3.get_object(
#     response_target: local_path,
#     bucket: bucket,
#     key: key
#   )
#   puts "Successfully downloaded #{key} to #{local_path}"
# rescue Aws::S3::Errors::NoSuchKey
#   puts "Key does not exist: #{key}"
# rescue => e
#   puts "Error downloading file: #{e.message}"
# end

# # Fetch identities and download their images
# Identity.find_each do |identity|
#   if identity.image_data
#     image_data = JSON.parse(identity.image_data)
#     image_key = "#{PREFIX}#{image_data['id']}"
#     puts "Image data: #{image_data}"
#     puts "Attempting to download image with key: #{image_key}"
#     local_image_path = File.join(LOCAL_STORAGE_PATH, image_data['id'])
#     download_file(s3, BUCKET_NAME, image_key, local_image_path)
#   end

#   if identity.banner_data
#     banner_data = JSON.parse(identity.banner_data)
#     banner_key = "#{PREFIX}#{banner_data['id']}"
#     puts "Banner data: #{banner_data}"
#     puts "Attempting to download banner with key: #{banner_key}"
#     local_banner_path = File.join(LOCAL_STORAGE_PATH, banner_data['id'])
#     download_file(s3, BUCKET_NAME, banner_key, local_banner_path)
#   end
# end