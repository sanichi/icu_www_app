IcuWwwApp::Application.routes.draw do
  root to: "pages#home"
  get "home" => "pages#home"

  resources :players
  
  namespace :admin do
    resources :users
  end

  match "*url", to: "pages#not_found", via: :all
end
