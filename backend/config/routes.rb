Rails.application.routes.draw do
  devise_for :users, path: 'auth', controllers: {
  sessions: 'auth/sessions'
}

  namespace :api do
    namespace :v1 do
      resource :user, only: [:show, :update]
      resources :tracks
      resources :jobs do
        member do
          post :publish
        end
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
