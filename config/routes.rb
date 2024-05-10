# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  require 'sidekiq/web'

  authenticate :admin_user do
    mount Sidekiq::Web => '/sidekiq'
  end
  resources :dashboard, only: :index
  get 'p/:handle', to: 'public_pages#show', as: :public_page

  resources :single_message, only: :index
  get 'sitemap.xml', to: 'sitemap#index', defaults: { format: 'xml' }

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    # sessions: 'users/sessions'
  }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  root 'dashboard#index'
end
