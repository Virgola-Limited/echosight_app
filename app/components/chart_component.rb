# app/components/chart_component.rb
class ChartComponent < ApplicationComponent
  def initialize(chart_id:, chart_type:, series_name:, series_data:, categories:, y_suffix: '')
    @chart_id = chart_id
    @chart_type = chart_type
    @series_name = series_name
    @series_data = series_data
    @categories = categories
    @y_suffix = y_suffix
  end

  def y_formatter
    <<-JS
      function (val) {
        if (val >= 1000000) {
          let formattedVal = (val / 1000000).toFixed(2);
          if (formattedVal.endsWith('00')) {
            formattedVal = (val / 1000000).toFixed(0);
          }
          return formattedVal + 'M#{@y_suffix}';
        } else if (val >= 1000) {
          let formattedVal = (val / 1000).toFixed(2);
          if (formattedVal.endsWith('00')) {
            formattedVal = (val / 1000).toFixed(0);
          }
          return formattedVal + 'K#{@y_suffix}';
        } else {
          return val.toFixed(2) + '#{@y_suffix}';
        }
      }
    JS
  end
end
