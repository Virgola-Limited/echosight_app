# frozen_string_literal: true
require 'sidekiq/web'

Rails.application.routes.draw do
  #########################################
  # admin
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  authenticate :admin_user do
    mount Sidekiq::Web => '/sidekiq'
    mount PgHero::Engine, at: "/pghero"
  end
  #########################################
  mount StripeEvent::Engine, at: '/stripe/webhook'
  root 'dashboard#index'


  resources :bug_reports, only: [:index, :create]
  resources :dashboard, only: :index
  resource :email_subscription, only: [:edit, :update]
  resources :feature_requests, only: [:index, :create]
  get 'p/:handle', to: 'public_pages#show', as: :public_page

  get 'landing', to: 'pages#landing'

  get 'track/open/:tracking_id', to: 'tracker#open'
  resources :single_message, only: :index
  get 'sitemap.xml', to: 'sitemap#index', defaults: { format: 'xml' }
  resource :subscription, only: [:new, :create, :show]
  resource :two_factor_authentication, only: [:show]
  post 'enable_two_factor_authentication', to: 'two_factor_authentications#enable'
  post 'disable_two_factor_authentication', to: 'two_factor_authentications#disable'

  resource :user_settings, only: [:edit, :update]
  resources :votes, only: [:create] # For upvoting

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    sessions: 'users/sessions'
  }
  devise_scope :user do
    get 'users/otp', to: 'users/sessions#new_otp', as: :new_otp_user_session
    post 'users/verify_otp', to: 'users/sessions#verify_otp', as: :verify_otp_user_session
  end
end
