IcuWwwApp::Application.routes.draw do
  root to: "pages#home"

  get  "sign_in"  => "sessions#new"
  get  "sign_out" => "sessions#destroy"
  get  "sign_up"  => "users#new"
  get  "redirect" => "redirects#redirect"

  %w[home links].each do |page|
    get page => "pages##{page}"
  end
  %w[shop cart card charge confirm completed].each do |page|
    match page => "payments##{page}", via: page == "charge" ? :post : :get
  end
  %w[account preferences update_preferences].each do |page|
    match "#{page}/:id" => "users##{page}", via: page.match(/^update/) ? :post : :get, as: page
  end
  (Global::ICU_PAGES + Global::ICU_DOCS.keys).each do |page|
    get "icu/#{page}" => "icu##{page}"
  end
  Global::HELP_PAGES.each do |page|
    get "help/#{page}" => "help##{page}"
  end

  resources :articles,    only: [:index, :show] do
    get :source, on: :member
  end
  resources :champions,   only: [:index, :show]
  resources :clubs,       only: [:index, :show]
  resources :downloads,   only: [:index, :show]
  resources :events,      only: [:index, :show]
  resources :games,       only: [:index, :show]
  resources :images,      only: [:index, :show]
  resources :items,       only: [:new, :create, :destroy]
  resources :new_players, only: [:create]
  resources :news,        only: [:index, :show] do
    get :source, on: :member
  end
  resources :player_ids,  only: [:index]
  resources :players,     only: [:index]
  resources :series,      only: [:index, :show]
  resources :sessions,    only: [:create]
  resources :tournaments, only: [:index, :show]
  resources :users,       only: [:new, :create] do
    get :verify, on: :member
  end

  namespace :admin do
    %w[session_info system_info test_email].each do |page|
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
    resources :downloads,       only: [:show, :new, :create, :edit, :update, :destroy]
    resources :events,          only: [:new, :create, :edit, :update, :destroy]
    resources :failures,        only: [:index, :show, :new, :update, :destroy]
    resources :fees do
      get :rollover, :clone, on: :member
    end
    resources :games,           only: [:edit, :update, :destroy]
    resources :images,          only: [:new, :create, :edit, :update, :destroy]
    resources :items,           only: [:index] do
      get :sales_ledger, on: :collection
    end
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
    resources :user_inputs,     only: [:show, :new, :create, :edit, :update, :destroy]
    resources :users do
      get :login, on: :member
    end
  end

  match "*url", to: "pages#not_found", via: :all
end
