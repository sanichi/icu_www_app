IcuWwwApp::Application.routes.draw do
  root to: "pages#home"

  get  "sign_in"  => "sessions#new"
  get  "sign_out" => "sessions#destroy"
  get  "sign_up"  => "users#new"
  get  "redirect" => "redirects#redirect"

  %w[home].each do |page|
    get page => "pages##{page}"
  end
  %w[shop cart card charge confirm completed].each do |page|
    match page => "payments##{page}", via: page == "charge" ? :post : :get
  end
  %w[account preferences update_preferences].each do |page|
    match "#{page}/:id" => "users##{page}", via: page.match(/^update/) ? :post : :get, as: page
  end

  resources :articles,    only: [:index, :show]
  resources :champions,   only: [:index, :show]
  resources :clubs,       only: [:index, :show]
  resources :events,      only: [:index, :show]
  resources :games,       only: [:index, :show]
  resources :images,      only: [:index, :show]
  resources :items,       only: [:new, :create, :destroy]
  resources :new_players, only: [:create]
  resources :news,        only: [:index, :show]
  resources :player_ids,  only: [:index]
  resources :players,     only: [:index]
  resources :series,      only: [:index, :show]
  resources :sessions,    only: [:create]
  resources :tournaments, only: [:index, :show]
  resources :uploads,     only: [:index, :show]
  resources :users,       only: [:new, :create] do
    get :verify, on: :member
  end

  namespace :admin do
    %w[system_info test_email].each do |page|
      get page => "pages##{page}"
    end

    resources :articles,        only: [:new, :create, :edit, :update, :destroy]
    resources :article_ids,     only: [:index]
    resources :bad_logins,      only: [:index]
    resources :carts,           only: [:index, :show, :edit, :update] do
      get :show_charge, on: :member
    end
    resources :cash_payments,   only: [:new, :create]
    resources :champions,       only: [:new, :create, :edit, :update, :destroy]
    resources :clubs,           only: [:new, :create, :edit, :update]
    resources :events,          only: [:new, :create, :edit, :update, :destroy]
    resources :fees do
      get :rollover, :clone, on: :member
    end
    resources :games,           only: [:edit, :update, :destroy]
    resources :images,          only: [:new, :create, :edit, :update, :destroy]
    resources :items,           only: [:index]
    resources :journal_entries, only: [:index, :show]
    resources :logins,          only: [:index, :show]
    resources :news,            only: [:new, :create, :edit, :update, :destroy]
    resources :payment_errors,  only: [:index]
    resources :pgns
    resources :players,         only: [:show, :new, :create, :edit, :update]
    resources :refunds,         only: [:index]
    resources :series,          only: [:new, :create, :edit, :update, :destroy]
    resources :tournaments,     only: [:new, :create, :edit, :update, :destroy]
    resources :translations,    only: [:index, :show, :edit, :update, :destroy]
    resources :uploads,         only: [:show, :new, :create, :edit, :update, :destroy]
    resources :user_inputs,     only: [:show, :new, :create, :edit, :update, :destroy]
    resources :users do
      get :login, on: :member
    end
  end

  match "*url", to: "pages#not_found", via: :all
end
