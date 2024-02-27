# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  require 'sidekiq/web'

  # Basic HTTP Authentication for Sidekiq Web UI
  unless Rails.env.development?
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      username == ENV['SITE_USERNAME'] && password == ENV['SITE_PASSWORD']
    end
  end
  mount Sidekiq::Web => '/sidekiq'

  resources :dashboard, only: :index
  get 'public_page/:handle', to: 'public_pages#show', as: :public_page

  resources :single_message, only: :index
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations'
  }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  root 'dashboard#index'

  post 'scraped_contents', to: 'scraped_contents#create'
end
