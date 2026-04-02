Rails.application.routes.draw do
  devise_for :users, path: 'auth', controllers: {
    sessions: 'auth/sessions',
    registrations: 'auth/registrations'
  }

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
      resource :user, only: [:show, :update]
      resources :tracks
      post 'matching', to: 'matching#create'
      resources :jobs, only: [:index, :show, :create], param: :uuid do
        resources :proposals, only: [:index, :create], param: :uuid
      end
      resources :proposals, only: [], param: :uuid do
        post :accept, on: :member
        post :reject, on: :member
      end
      resources :production_requests, only: [:index, :show, :create], param: :uuid do
        member do
          post :accept
          post :reject
          post :withdraw
        end
      end
      resources :conversations, only: [:index, :show, :create] do
        resources :messages, only: [:index, :create]
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
