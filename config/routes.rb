Rails.application.routes.draw do
  resources :routes do
    collection do
      get :add_config_rule
      get :remove_config_rule
      post :apply_config_rule
    end
  end
end
