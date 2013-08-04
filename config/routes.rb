IcuWwwApp::Application.routes.draw do
  root to: "pages#home"
  get "home" => "pages#home"

  resources :players
  
  match "*url", to: "pages#not_found", via: :all
end
