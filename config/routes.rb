Rails.application.routes.draw do
  devise_for :users, path: 'auth', controllers: {
  sessions: 'auth/sessions'
}

  namespace :api do
    namespace :v1 do
      resources :tracks, only: %i[index show create]
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  get '/me', to: 'me#show'
end
