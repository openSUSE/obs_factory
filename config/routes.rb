ObsFactory::Engine.routes.draw do
  # Summary of the staging state (as a dashboard or a JSON structure)
  get '/staging_projects' => 'staging_projects#list'
  # Used to enforce the refresh of the cache of jobs (using cache=refresh)
  get '/openqa_jobs' => 'openqa_jobs#list'
end
