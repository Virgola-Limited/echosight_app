# lib/tasks/cleanup.rake

# **** UNTESTED *****
namespace :shrine do
  desc 'Delete unused files from Shrine S3 storage'
  task delete_unused: :environment do
    require 'shrine'

    # Retrieve the S3 storage (or local storage) based on your configuration
    storage = Shrine.storages[:store]

    if storage.is_a?(Shrine::Storage::S3)
      all_files = storage.list(prefix: 'store') # Lists files in the S3 'store' prefix
    else
      all_files = Dir.glob(File.join(storage.directory, '**', '*')).map do |file|
        file.sub(storage.directory + '/', '')
      end
    end

    # Collect IDs of all files still associated with current records
    used_files = Identity.pluck(:image_data, :banner_data).flat_map do |image_data, banner_data|
      [image_data, banner_data].compact.map { |data| Shrine::UploadedFile.new(JSON.parse(data)).id }
    end

    # Determine which files are not used
    unused_files = all_files - used_files

    # Remove each unused file from the storage
    unused_files.each do |file_id|
      storage.delete(file_id)
      puts "Deleted unused file: #{file_id}"
    end

    puts 'Unused files cleanup completed!'
  end
end
