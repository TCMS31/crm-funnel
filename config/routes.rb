# frozen_string_literal: true

Rails.application.routes.draw do
  root 'dashboard#show'

  get 'up', to: 'health#show', as: :health

  resource :dashboard, only: :show
  resources :users
  resources :companies, except: :show
  resources :deals, only: %i[index show new create] do
    resources :histories, only: %i[new create]
  end
end
