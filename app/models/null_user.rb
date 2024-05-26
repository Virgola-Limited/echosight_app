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

end