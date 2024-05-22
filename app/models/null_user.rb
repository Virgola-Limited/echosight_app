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

  def user_should_be_syncing?
    true
  end

end