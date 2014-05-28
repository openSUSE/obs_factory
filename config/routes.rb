ObsFactory::Engine.routes.draw do
  get '/staging_projects' => 'staging_projects#list'
end
