class UnclaimedUser
  attr_reader :identity

  def initialize(identity:)
    @identity = identity
    raise ArgumentError, 'identity is required' if identity.nil?
  end

  def id
    identity.uid
  end

  def name

  end

  def handle
    identity.handle
  end

  def guest?
    false
  end

  def syncable?
    identity.syncable?
  end

  def hide_profile_banner?
    false
  end

  def image_url
    if identity.image_data.present?
      image_data = identity.image_data.is_a?(String) ? JSON.parse(identity.image_data) : identity.image_data
      generate_shrine_image_url(image_data)
    else
      nil
    end
  end

  private

  def generate_shrine_image_url(image_data)
    storage_key = image_data['storage']
    file_id = image_data['id']

    Shrine.storages[storage_key.to_sym].url(file_id)
  end
end
