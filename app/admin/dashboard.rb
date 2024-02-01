ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    section "Incomplete User Twitter Data Updates" do
      table_for UserTwitterDataUpdate.joins(identity: :user).where(completed_at: nil).order('started_at DESC').limit(10) do
        column :started_at
        column "Error Message", :error_message
        column "Identity UID", :identity_id do |update|
          update.identity.uid # Assuming `uid` is a column in your `identities` table
        end
        column "User Email", :identity_id do |update|
          update.identity.user.email # Adjust according to your user association
        end
      end
    end
  end # content
end
