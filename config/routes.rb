IcuWwwApp::Application.routes.draw do
  root to: "pages#home"

  %w[home system_info].each do |page|
    get page => "pages##{p}"
  end
  get "sign_in"  => "sessions#new"
  get "sign_out" => "sessions#destroy"
  get "redirect" => "redirects#redirect"

  resources :sessions,   only: [:create]
  resources :users,      only: [:show, :edit, :update]
  resources :clubs,      only: [:index, :show]
  resources :players,    only: [:index]
  resources :player_ids, only: [:index]

  namespace :admin do
    resources :bad_logins,        only: [:index]
    resources :clubs,             only: [:new, :create, :edit, :update]
    resources :journal_entries,   only: [:index, :show]
    resources :logins,            only: [:index, :show]
    resources :players,           only: [:show, :new, :create, :edit, :update]
    resources :subscription_fees do
      get :rollover, on: :member
    end
    resources :entry_fees do
      get :rollover, on: :member
    end
    resources :translations,      only: [:index, :show, :edit, :update, :destroy]
    resources :users do
      get :login, on: :member
    end
  end

  match "*url", to: "pages#not_found", via: :all
end
