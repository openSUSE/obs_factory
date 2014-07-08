module ObsFactory
  # Poor man's asset digest
  STATIC_VERSION = 1

  class Engine < ::Rails::Engine
    isolate_namespace ObsFactory

    initializer :copy_static do |app|
      unless app.root.to_s.match root.to_s
        target = File.join(app.root.to_s, 'public', 'stylesheets', 'obs_factory')
        source = File.join(root.to_s, 'public', 'stylesheets', 'application.css')
        FileUtils.mkdir_p(target)
        FileUtils.cp(source, File.join(target, "application-#{ObsFactory::STATIC_VERSION}.css"))
      end
    end
  end
end
