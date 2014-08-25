ObsFactory::Engine.routes.draw do
  resources :distributions, only: [:show], constraints: {id: %r{[^\/]*}} do
    # Status of staging projects (as status pages or as JSON structures)
    resources :staging_projects, only: [:index, :show], controller: :staging_projects
  end
  # Used to enforce the refresh of the cache of jobs (using cache=refresh)
  get '/openqa_jobs' => 'openqa_jobs#index'
end
