ActiveAdmin.register ApiBatch do

  actions :index, :show

  index do
    selectable_column
    id_column
    column :completed_at
    column :tweet_ids
    column :status
    actions  # Ensure this is added to display the default actions including the delete option
  end

end
