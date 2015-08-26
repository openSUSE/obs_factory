module ObsFactory
  module ApplicationHelper

    # Catch some url helpers used in the OBS layout and forward them to
    # the main application
    %w(root_path project_show_path search_path user_show_url user_show_path user_logout_path
       user_login_path user_register_user_path user_do_login_path news_feed_path project_toggle_watch_path 
       project_list_public_path monitor_path projects_path).each do |m|
      define_method(m) do |*args|
        main_app.send(m, *args)
      end
    end

  end
end
