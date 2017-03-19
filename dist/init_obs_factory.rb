require '/usr/share/obs-factory-engine/lib/obs_factory.rb'

class LoadFactoryEngine < OBSEngine::Base
  def self.mount_it
    OBSApi::Application.routes.draw do
      mount ObsFactory::Engine => '/'
    end
  end
end
