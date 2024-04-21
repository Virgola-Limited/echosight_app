# frozen_string_literal: true

# == Schema Information
#
# Table name: api_batches
#
#  id           :bigint           not null, primary key
#  completed_at :datetime
#  status       :string           default("pending")
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
FactoryBot.define do
  factory :api_batch do

  end
end
