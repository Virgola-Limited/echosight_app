ActiveAdmin.register_page "PgHero" do
  menu priority: 10, label: 'PgHero'

  content title: 'PgHero' do
    div id: "pghero-content" do
      # Using a direct path as a workaround
      iframe src: "/pghero", style: "width:100%;height:100vh;border:none;"
    end
  end
end
