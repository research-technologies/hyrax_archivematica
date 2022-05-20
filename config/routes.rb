# frozen_string_literal: true

HyraxArchivematica::Engine.routes.draw do
  # Generic work routes
  resources :works, only: [] do
    member do
      resources :archives, as: :work_archives, only: [:new, :create]
    end
  end
end
