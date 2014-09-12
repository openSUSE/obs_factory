ObsFactory::Engine.routes.draw do
  cons = { project: %r{[^\/]*} }
  get 'project/dashboard/:project' => "distributions#show", as: 'dashboard', constraints: cons
  get 'project/staging_projects/:project' => "staging_projects#index", as: 'staging_projects', constraints: cons
  get 'project/staging_projects/:project/:id' => "staging_projects#show", as: 'staging_project', contraints: cons

  # Used to enforce the refresh of the cache of jobs (using cache=refresh)
  get 'openqa_jobs' => 'openqa_jobs#index'

  # Compatibility with old build.opensuse.org routes
  old_mount_point = 'factory'
  get "#{old_mount_point}/dashboard", to: redirect('project/dashboard/openSUSE:Factory')
  get "#{old_mount_point}/staging_projects", to: redirect('project/staging_projects/openSUSE:Factory')
  get "#{old_mount_point}/staging_projects/:id", to: redirect('project/staging_projects/openSUSE:Factory/%{id}')
  get "#{old_mount_point}/openqa_jobs", to: redirect('openqa_jobs')
end
