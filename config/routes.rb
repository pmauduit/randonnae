Randonnae::Application.routes.draw do
  root :to => "home#index"
  get "home/index"
  match "/auth/:provider/callback" => "sessions#create"
  match "/signout" => "sessions#destroy", :as => :signout
end
