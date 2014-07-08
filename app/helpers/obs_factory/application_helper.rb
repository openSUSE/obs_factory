module ObsFactory
  module ApplicationHelper

    # Catch some url helpers used in the OBS layout and forward them to
    # the main application
    %w(root_path project_show_path search_path user_show_url user_show_path user_logout_path
       user_login_path user_register_user_path user_do_login_path news_feed_path
       project_list_public_path monitor_path).each do |m|
      define_method(m) do |*args|
        main_app.send(m, *args)
      end
    end

    # Outputs the first elements of a colection calling to its partial when
    # needed
    #
    # @param [Enumerable]  collection  collection of strings or objects
    # @param [Integer]  length  number of elements to print
    # @return [String]  the first elements and the count of skipped ones
    def short_sentence(collection, length = 2)
      list = collection[0,2].map do |i|
        if i.kind_of? String
          i
        else
          render(i).chomp
        end
      end
      out = list.join(", ").html_safe
      out << " and #{collection.size-2} more".html_safe if collection.size > 2
      out
    end
  end
end
