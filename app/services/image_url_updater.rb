class ImageUrlUpdater
  def initialize(bucket, region)
    @bucket = bucket
    @region = region
    @host = "https://#{bucket}.#{region}.digitaloceanspaces.com"
  end

  def update_all
    update_identities
    update_content_items
    puts "Finished updating all image URLs."
  end

  def update_identities
    puts "Updating Identity images and banners..."
    Identity.find_each do |identity|
      update_attachment(identity, :image)
      update_attachment(identity, :banner)
    end
    puts "Finished updating Identity images and banners."
  end

  def update_content_items
    puts "Updating ContentItem images..."
    ContentItem.find_each do |content_item|
      update_attachment(content_item, :image)
    end
    puts "Finished updating ContentItem images."
  end

  private

  def update_attachment(record, attachment_name)
    attachment_data = record.send("#{attachment_name}_data")
    if attachment_data.present?
      data = JSON.parse(attachment_data)
      if data['storage'] == 'store'
        new_url = "#{@host}/#{data['id']}"
        data['url'] = new_url
        record.update_column("#{attachment_name}_data", data.to_json)
        puts "Updated #{record.class.name} #{record.id} #{attachment_name}"
      end
    end
  rescue => e
    puts "Error updating #{record.class.name} #{record.id} #{attachment_name}: #{e.message}"
  end
end

# updater = ImageUrlUpdater.new('echosight-production', 'nyc3')
# updater.update_content_items