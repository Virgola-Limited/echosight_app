ActiveAdmin.register_page "Sidekiq" do
  menu priority: 10, label: 'Sidekiq'

  content title: 'Sidekiq' do
    div id: "sidekiq-content" do
      # Using a direct path as a workaround
      iframe src: "/sidekiq", style: "width:100%;height:100vh;border:none;"
    end
  end
end
