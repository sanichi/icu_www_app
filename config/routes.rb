IcuWwwApp::Application.routes.draw do
  root to: "pages#home"

  %w[home shop system_info].each do |page|
    get page => "pages##{page}"
  end
  get "sign_in"  => "sessions#new"
  get "sign_out" => "sessions#destroy"
  get "redirect" => "redirects#redirect"

  resource  :cart,              only: [:show]
  resources :cart_items,        only: [:destroy]
  resources :clubs,             only: [:index, :show]
  resources :entries,           only: [:new, :create]
  resources :player_ids,        only: [:index]
  resources :players,           only: [:index]
  resources :sessions,          only: [:create]
  resources :subscriptions,     only: [:new, :create]
  resources :users,             only: [:show, :edit, :update]

  namespace :admin do
    resources :bad_logins,        only: [:index]
    resources :clubs,             only: [:new, :create, :edit, :update]
    resources :entry_fees do
      get :rollover, :clone, on: :member
    end
    resources :journal_entries,   only: [:index, :show]
    resources :logins,            only: [:index, :show]
    resources :players,           only: [:show, :new, :create, :edit, :update]
    resources :subscription_fees do
      get :rollover, on: :member
    end
    resources :translations,      only: [:index, :show, :edit, :update, :destroy]
    resources :users do
      get :login, on: :member
    end
  end

  match "*url", to: "pages#not_found", via: :all
end
