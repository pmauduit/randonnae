Randonnae::Application.routes.draw do
  root :to => "home#index"
  get "home/index"
  match "/auth/:provider/callback" => "sessions#create"
  match "/signout" => "sessions#destroy", :as => :signout

  match "/treks/:id/gpx" => "treks#getgpx"
  match "/treks/:id/imgs" => "treks#getimagesinfo"
  match "/users/:id/treks" => "treks#indexbyuser"

  resources :treks
end
