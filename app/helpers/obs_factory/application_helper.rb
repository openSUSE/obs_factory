module ObsFactory
  module ApplicationHelper

    # Catch some url helpers used in the OBS layout and forward them to
    # the main application
    %w(root_path project_show_path search_path user_show_url user_show_path logout_path
       news_feed_path public_projects_path monitor_path).each do |m|
      define_method(m) do |*args|
        main_app.send(m, args)
      end
    end
  end
end
