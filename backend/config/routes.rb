Rails.application.routes.draw do
  devise_for :users, path: 'auth', controllers: {
    sessions: 'auth/sessions',
    registrations: 'auth/registrations'
  }

  namespace :api do
    namespace :v1 do
      resource :user, only: [:show, :update]
      resources :tracks
      resources :jobs, only: [:index, :show, :create, :update], param: :uuid do
        collection do
          get :my_jobs
        end
        post :publish, on: :member
        resources :proposals, only: [:index, :create], param: :uuid
      end
      resources :proposals, only: [], param: :uuid do
        collection do
          get :my_proposals
        end
        post :accept, on: :member
        post :reject, on: :member
      end
      resources :conversations, only: [:index, :show, :create] do
        resources :messages, only: [:create]
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
