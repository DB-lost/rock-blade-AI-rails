Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  root "home#index"

  resource :session
  resources :passwords, param: :token

  # 注册相关路由
  resource :registration, only: [ :new, :create ] do
    collection do
      post :send_verification_code
      post :change_step
      get :registration_user
    end
  end
  get "sign_up" => "registrations#new", as: :sign_up

  get "ai_chats" => "ai_chats#index"

  # 助手相关路由
  resources :assistants do
    member do
      post :duplicate    # 复制助手
      delete :clear_topics  # 清空所有话题
      post :set_last_used  # 设置最后使用的助手
    end

    resources :conversations, only: [ :create, :show, :destroy ]
  end
end
