class PostsController < AuthenticatedController
  include Pagy::Backend

  def index
    if params[:query].present?
      query = params[:query].split.map { |word| "#{word}:*" }.join(' & ')
      tsquery = ActiveRecord::Base.sanitize_sql_array(["to_tsquery('english', ?)", query])

      results = current_user.tweets.where("searchable @@ #{tsquery}")
                     .order(Arel.sql("ts_rank(searchable, #{tsquery}) DESC"))

    else
      results = current_user.tweets
    end

    @pagy, @posts = pagy(results, items: 5)
  end
end
