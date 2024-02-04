class DefaultOrderClause < ActiveAdmin::OrderClause
  def to_sql
    if field.blank?
      'created_at DESC' # default sort order
    else
      super # use the default behavior for specified sort orders
    end
  end
end
