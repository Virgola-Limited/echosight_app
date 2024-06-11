class NullUser
  def id
    nil
  end

  def name
    'Guest User'
  end

  def guest?
    true
  end

  def identity
    nil
  end

  def syncable?
    false
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