IcuWwwApp::Application.routes.draw do
  root to: "pages#home"

  get "home"     => "pages#home"
  get "sign_in"  => "sessions#new"
  get "sign_out" => "sessions#destroy"

  resources :sessions, only: [:create]
  resources :users,    only: [:show, :edit, :update]
  
  namespace :admin do
    resources :users,  only: [:index, :show, :edit, :update, :destroy] do
      get :login, on: :member
    end
    resources :logins,       only: [:index, :show]
    resources :translations, only: [:index, :show, :edit, :update, :destroy]
  end

  match "*url", to: "pages#not_found", via: :all
end
