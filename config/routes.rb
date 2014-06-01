ObsFactory::Engine.routes.draw do
  get '/staging_projects' => 'staging_projects#list'
  get '/openqa_jobs' => 'openqa_jobs#list'
end
