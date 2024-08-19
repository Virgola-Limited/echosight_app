# == Schema Information
#
# Table name: request_logs
#
#  id         :bigint           not null, primary key
#  endpoint   :string           not null
#  metadata   :jsonb            not null
#  params     :jsonb            not null
#  response   :jsonb            not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_request_logs_on_created_at  (created_at)
#  index_request_logs_on_endpoint    (endpoint)
#
# app/models/request_log.rb
class RequestLog < ApplicationRecord
  # Assuming you've created a migration for this model with the following fields:
  # t.string :endpoint
  # t.jsonb :params
  # t.jsonb :response
  # t.jsonb :metadata
  # t.timestamps

  scope :recent, -> { where('created_at > ?', 2.weeks.ago) }

  def self.cleanup_old_logs
    where('created_at <= ?', 2.weeks.ago).delete_all
  end
end
