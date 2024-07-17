# frozen_string_literal: true

ActiveAdmin.register Identity do
  permit_params :user_id, :created_at, :updated_at, :description, :handle, :image_data, :banner_data, :uid, :provider, :sync_without_user

  actions :index, :show, :destroy, :new, :edit, :create, :update

  controller do
    def scoped_collection
      super.sorted_by_followers_count
    end

    def apply_sorting(chain)
      params[:order] = 'max_followers_count_desc' if params[:order].blank?
      super
    end
  end

  index do
    selectable_column
    id_column
    column :user_id
    column :uid
    column :created_at
    column :updated_at
    column :description
    column :handle
    column :sync_without_user
    column :image_url
    column :banner_url

    column :followers_count do |identity|
      recent_metric = identity.twitter_user_metrics.order(date: :desc).first
      recent_metric ? recent_metric.followers_count : 'N/A'
    end

    column :vip_since do |identity|
      unless identity.user
        'No user'
      else
        identity.user.vip_since
      end
    end

    actions defaults: true do |identity|
      link_to 'Public Page', public_page_path(handle: identity.handle), target: '_blank'
    end
  end

  filter :handle
  filter :sync_without_user

  form do |f|
    f.semantic_errors

    f.inputs do
      f.input :user, as: :select, collection: User.all.collect { |user| [user.email, user.id] }, include_blank: true
      f.input :description
      f.input :uid
      f.input :handle
      f.input :provider, input_html: { value: f.object.provider || 'twitter' }
      f.input :sync_without_user
    end

    f.actions
  end

  active_admin_import validate: true,
                      batch_transaction: true,
                      csv_options: { col_sep: "\t" },
                      before_batch_import: lambda { |importer|
                        puts "Debug: CSV headers: #{importer.headers.inspect}"
                        processed_lines = []
                        importer.csv_lines.each_with_index do |row, index|
                          puts "Debug: Row #{index} before: #{row.inspect}"
                          if row.is_a?(Hash)
                            row[:provider] = 'twitter'
                            unless Identity.exists?(uid: row[:uid], provider: row[:provider])
                              processed_lines << row
                            else
                              puts "Skipping duplicate identity with UID: #{row[:uid]}"
                            end
                          elsif row.is_a?(Array)
                            headers = importer.headers.keys
                            uid_index = headers.index('uid')
                            handle_index = headers.index('handle')
                            if uid_index.nil? || handle_index.nil?
                              puts "Error: Required column not found in headers."
                            else
                              row_hash = Hash[headers.zip(row)]
                              row_hash[:provider] = 'twitter'
                              unless Identity.exists?(uid: row[uid_index], provider: 'twitter')
                                processed_lines << row_hash
                              else
                                puts "Skipping duplicate identity with UID: #{row[uid_index]}"
                              end
                            end
                          else
                            puts "Warning: Unexpected row format at index #{index}: #{row.inspect}"
                          end
                          puts "Debug: Row #{index} after: #{row.inspect}"
                        end
                        importer.instance_variable_set(:@csv_lines, processed_lines)
                        puts "Debug: Updated CSV lines: #{processed_lines.size}"
                      },
                      after_batch_import: lambda { |importer|
                        puts "Batch import completed"
                        puts "Debug: Importer object methods: #{importer.methods.sort}"
                        puts "Debug: Importer instance variables: #{importer.instance_variables}"
                      },
                      after_import: lambda { |importer|
                        puts "Import completed"
                        puts "Debug: Importer object methods: #{importer.methods.sort}"
                        puts "Debug: Importer instance variables: #{importer.instance_variables}"

                        if importer.respond_to?(:result) && importer.result
                          total_imported = importer.result.respond_to?(:num_inserts) ? importer.result.num_inserts : 'Unknown'
                          total_failed = importer.result.respond_to?(:failed_instances) ? importer.result.failed_instances.count : 'Unknown'

                          if importer.result.respond_to?(:failed_instances) && !importer.result.failed_instances.empty?
                            puts "Debug: First failed instance errors: #{importer.result.failed_instances.first.errors.full_messages}"
                          end
                        else
                          total_imported = 'Unknown'
                          total_failed = 'Unknown'
                        end

                        Rails.logger.info "Import process completed"
                        Rails.logger.info "Successfully imported: #{total_imported}"
                        Rails.logger.info "Failed to import: #{total_failed}"

                        if importer.respond_to?(:result) && importer.result && importer.result.respond_to?(:failed_instances)
                          duplicates = importer.result.failed_instances.select { |instance| instance.errors[:uid].include?('has already been taken') || instance.errors[:handle].include?('has already been taken') }
                          Rails.logger.info "Duplicate identities: #{duplicates.map(&:uid).join(', ')}"
                        end

                        puts "Import results:"
                        puts "  Total successful imports: #{total_imported}"
                        puts "  Total failed imports: #{total_failed}"
                      }

  batch_action :set_sync_without_user_true, confirm: "Are you sure you want to set sync_without_user to true for selected identities?" do |ids|
    Identity.where(id: ids).update_all(sync_without_user: true)
    redirect_to collection_path, notice: "The sync_without_user attribute has been set to true for the selected identities."
  end

  batch_action :set_sync_without_user_false, confirm: "Are you sure you want to set sync_without_user to false for selected identities?" do |ids|
    Identity.where(id: ids).update_all(sync_without_user: false)
    redirect_to collection_path, notice: "The sync_without_user attribute has been set to false for the selected identities."
  end
end
