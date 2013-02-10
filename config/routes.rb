Randonnae::Application.routes.draw do
  root :to => "home#index"
  get "home/index"
  match "/auth/:provider/callback" => "sessions#create"
  match "/signout" => "sessions#destroy", :as => :signout

  match "/treks/:id/gpx" => "treks#get_gpx"
  match "/treks/:id/imgs" => "treks#get_images_info"
  match "/treks/user/:id" => "treks#index_by_user"
  match "/treks/:id/details" => "treks#get_elevation_details"

  match "/treks/:trek_id/picture/:image_id" => "images#get_image"
  match "/treks/:trek_id/thumbnail/:image_id" => "images#get_thumbnail"
  match "/treks/:trek_id/min/:image_id" => "images#get_min_image"

  resources :treks
end
