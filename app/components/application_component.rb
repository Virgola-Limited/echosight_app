# app/components/application_component.rb
class ApplicationComponent <  ViewComponent::Base
  include ApplicationHelper  # Option 1: Include all helpers from ApplicationHelper
  # or
  delegate :link_to, to: :helpers  # Option 2: Delegate link_to method to the helpers method
end
