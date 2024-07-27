class PostsController < AuthenticatedController
  include Pagy::Backend

  def index
    if params[:query].present?
      query = params[:query].split.map { |word| "#{word}:*" }.join(' & ')
      tsquery = ActiveRecord::Base.sanitize_sql_array(["to_tsquery('english', ?)", query])

      results = Tweet.where("searchable @@ #{tsquery}")
                     .order(Arel.sql("ts_rank(searchable, #{tsquery}) DESC"))
    else
      results = Tweet.all
    end

    @pagy, @posts = pagy(results, items: 5)

    Rails.logger.debug("paul Results class: #{results.class.name}")
    Rails.logger.debug("paul Pagination: #{@pagy.inspect}")
    Rails.logger.debug("paul Posts count after pagination: #{@posts.count}")
  end
end
