require 'aws-sdk-s3'

class BucketSyncService
  def initialize(source_config, dest_config)
    @source_client = create_client(source_config)
    @dest_client = create_client(dest_config)
    @source_bucket = source_config[:bucket_name]
    @dest_bucket = dest_config[:bucket_name]
  end

  def sync
    source_objects.each do |object|
      sync_object(object) if object_needs_sync?(object)
    end
    puts "Sync completed successfully!"
  end

  private

  def create_client(config)
    client_options = {
      region: config[:region],
      access_key_id: config[:access_key_id],
      secret_access_key: config[:secret_access_key],
    }

    # Add endpoint for Digital Ocean Spaces
    if config[:endpoint]
      client_options[:endpoint] = config[:endpoint]
      client_options[:force_path_style] = true
    end

    Aws::S3::Client.new(client_options)
  end

  def source_objects
    @source_client.list_objects_v2(bucket: @source_bucket).contents
  end

  def object_needs_sync?(object)
    source_etag = object.etag.gsub('"', '')
    dest_etag = get_object_etag(@dest_client, @dest_bucket, object.key)
    source_etag != dest_etag
  end

  def get_object_etag(client, bucket, key)
    client.head_object(bucket: bucket, key: key).etag.gsub('"', '')
  rescue Aws::S3::Errors::NotFound
    nil
  end

  def sync_object(object)
    puts "Syncing: #{object.key}"
    response = @source_client.get_object(bucket: @source_bucket, key: object.key)
    @dest_client.put_object(
      bucket: @dest_bucket,
      key: object.key,
      body: response.body.read,
      content_type: response.content_type
    )
  end
end

source_config = {
  region: ENV['BUCKETEER_AWS_REGION'],
  access_key_id: ENV['BUCKETEER_AWS_ACCESS_KEY_ID'],
  secret_access_key: ENV['BUCKETEER_AWS_SECRET_ACCESS_KEY'],
  bucket_name: ENV['BUCKETEER_BUCKET_NAME']
}

# Destination config (Digital Ocean Spaces)
dest_config = {
  region: ENV['DO_SPACE_REGION'],
  access_key_id: ENV['DO_SPACE_ACCESS_KEY_ID'],
  secret_access_key: ENV['DO_SPACE_SECRET_ACCESS_KEY'],
  bucket_name: ENV['DO_SPACE_NAME'],
  endpoint: ENV['DO_SPACE_ENDPOINT']
}

# Create and run the service
# sync_service = BucketSyncService.new(source_config, dest_config)
# sync_service.sync