# frozen_string_literal: true

class UserTwitterDataUpdate < ApplicationRecord
  belongs_to :identity

  def self.ransackable_associations(auth_object = nil)
    ["identity"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["completed_at", "created_at", "error_message", "id", "id_value", "identity_id", "started_at", "updated_at"]
  end
end
