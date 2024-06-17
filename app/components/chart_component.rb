# app/components/chart_component.rb
class ChartComponent < ViewComponent::Base
  def initialize(chart_id:, chart_type:, series_name:, series_data:, categories:, y_formatter:, y_suffix: '')
    @chart_id = chart_id
    @chart_type = chart_type
    @series_name = series_name
    @series_data = series_data
    @categories = categories
    @y_formatter = y_formatter
    @y_suffix = y_suffix
  end
end
