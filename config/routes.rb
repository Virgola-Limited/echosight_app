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
    get 'admin/analytics_dashboard', to: 'admin/analytics#dashboard'
  end
  #########################################
  mount StripeEvent::Engine, at: '/stripe/webhook'
  root 'pages#landing'


  resources :bug_reports, only: [:index, :create]
  resources :content_items, only: [:index]
  resources :dashboard, only: :index
  resource :email_subscription, only: [:edit, :update]
  get 'faq', to: 'pages#faq'
  resources :feature_requests, only: [:index, :create]
  get 'landing', to: 'pages#landing'
  get 'leaderboard', to: 'leaderboard#users'
  resources :posts, only: [:index]
  get 'p/:handle', to: 'public_pages#show', as: :public_page
  get 'track/open/:tracking_id', to: 'tracker#open'
  get 'leaderboard/tweets', to: 'leaderboard#tweets'

  resources :single_message, only: :index
  get 'sitemap.xml', to: 'sitemap#index', defaults: { format: 'xml' }
  resource :subscription, only: [:new, :create, :show]
  resource :two_factor_authentication, only: [:show]
  post 'enable_two_factor_authentication', to: 'two_factor_authentications#enable'
  post 'disable_two_factor_authentication', to: 'two_factor_authentications#disable'

  resource :user_settings, only: [:edit, :update]
  resources :votes, only: [:create] # For upvoting

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations',
    confirmations: 'users/confirmations',
    sessions: 'users/sessions',
    masquerades: "users/masquerades"
  }
  devise_scope :user do
    get 'users/otp', to: 'users/sessions#new_otp', as: :new_otp_user_session
    post 'users/verify_otp', to: 'users/sessions#verify_otp', as: :verify_otp_user_session
    post 'masquerade', to: 'users/masquerades#show', as: :masquerade
    post 'back_masquerade', to: 'users/masquerades#back', as: :back_masquerade
  end
end
