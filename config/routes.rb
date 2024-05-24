# frozen_string_literal: true
require 'sidekiq/web'

Rails.application.routes.draw do
  #########################################
  # admin
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  authenticate :admin_user do
    mount Sidekiq::Web => '/sidekiq'
  end
  #########################################
  mount StripeEvent::Engine, at: '/stripe/webhook'

  resources :dashboard, only: :index
  root 'dashboard#index'



  resource :email_subscription, only: [:edit, :update]
  get 'p/:handle', to: 'public_pages#show', as: :public_page

  get 'landing', to: 'pages#landing'

  resources :single_message, only: :index
  get 'sitemap.xml', to: 'sitemap#index', defaults: { format: 'xml' }
  resource :subscription, only: [:new, :create, :show]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    # sessions: 'users/sessions'
  }
end
