# frozen_string_literal: true

class PaginationComponent < ViewComponent::Base
  include Pagy::Frontend

  attr_reader :pagy

  def initialize(pagy:)
    @pagy = pagy
  end

  def showing_text
    "Showing <span class=\"font-semibold text-gray-900 dark:text-white\">#{pagy.from}</span> to <span class=\"font-semibold text-gray-900 dark:text-white\">#{pagy.to}</span> of <span class=\"font-semibold text-gray-900 dark:text-white\">#{pagy.count}</span> Entries"
  end

  def prev_url
    pagy_url_for(pagy, pagy.prev) if pagy.prev
  end

  def next_url
    pagy_url_for(pagy, pagy.next) if pagy.next
  end
end