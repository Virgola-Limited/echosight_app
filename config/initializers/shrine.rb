require "shrine"
require "shrine/storage/file_system"

Shrine.storages = {
  cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"), # temporary
  store: Shrine::Storage::FileSystem.new("public", prefix: "uploads/store"), # permanent
}

Shrine.plugin :activerecord # loads ActiveRecord integration

# :cached_attachment_data Plugin: This plugin is particularly useful if your users might need to re-display forms due to validation errors or other reasons. It enables your application to retain the uploaded file in the cache, so the user doesn't have to re-upload it if the form needs to be redisplayed. This can significantly improve the user experience, especially when dealing with large files.

# :restore_cached_data Plugin: This plugin complements the :cached_attachment_data plugin by extracting and retaining the metadata for the cached files when a form is re-displayed. This means that all the file metadata (like size, type, filename, etc.) is preserved and available in your application even before the file is permanently stored. This can be useful for validation or displaying file information back to the user in the case of form errors.

# Shrine.plugin :cached_attachment_data # enables retaining cached file across form redisplays
# Shrine.plugin :restore_cached_data    # extracts metadata for assigned cached files