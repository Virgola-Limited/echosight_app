class ImageUploader < Shrine
  plugin :determine_mime_type
  # plugins and uploading logic
end