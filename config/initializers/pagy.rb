# config/initializers/pagy.rb

require 'pagy/extras/overflow'

Pagy::DEFAULT[:overflow] = :last_page  # default :empty_page
Pagy::DEFAULT[:items] = 5              # default items per page
