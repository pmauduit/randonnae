Randonnae::Application.routes.draw do
  root :to => "home#index"
  get "home/index"
  match "/auth/:provider/callback" => "sessions#create"
  match "/signout" => "sessions#destroy", :as => :signout

  match "/treks/:id/gpx" => "treks#getgpx"
  match "/treks/:id/imgs" => "treks#getimagesinfo"
  match "/treks/user/:id" => "treks#index_by_user"

  match "/treks/:id/picture/:name" => "treks#getimage"

  match "/treks/:id/thumbnail/:name" => "treks#getthumbnail"
  match "/treks/:id/min/:name" => "treks#getminimage"

  match "/treks/:id/details" => "treks#getdetails"
  resources :treks
end
