Randonnae::Application.routes.draw do
  root :to => "home#index"
  get "home/index"
  match "/auth/:provider/callback" => "sessions#create"
  match "/signout" => "sessions#destroy", :as => :signout

  match "/treks/:id/gpx" => "treks#getgpx"
  match "/treks/:id/imgs" => "treks#getimagesinfo"
  match "/treks/user/:id" => "treks#indexbyuser"

  match "/treks/:id/picture/:name" => "treks#getimage"

  match "/treks/:id/thumbnail/:name" => "treks#getthumbnail"

  resources :treks
end
