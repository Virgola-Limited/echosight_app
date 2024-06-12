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
    identity.description
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
    nil
  end

  def handle
    nil
  end
end
