ObsFactory::Engine.routes.draw do
  # Status of staging projects (as status pages or as JSON structures)
  resources :staging_projects, only: [:index, :show]
  # Used to enforce the refresh of the cache of jobs (using cache=refresh)
  get '/openqa_jobs' => 'openqa_jobs#index'
end
