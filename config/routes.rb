# frozen_string_literal: true

Rails.application.routes.draw do
  require 'sidekiq/web'

  # Basic HTTP Authentication for Sidekiq Web UI
  Sidekiq::Web.use Rack::Auth::Basic do |username, password|
    # TODO: Move to ENV variables or just disable in production
    username == 'admin' && password == 'l0ftw@h'
  end
  mount Sidekiq::Web => '/sidekiq'

  resources :dashboard, only: :index
  get 'public_page/:twitter_handle', to: 'public_pages#show', as: :public_page

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
end
