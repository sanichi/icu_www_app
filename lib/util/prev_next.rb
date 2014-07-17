#
# This utility cooperates with save_last_search in controllers/application_controller.rb
# and with the id_list method of models/concerns/pageable.rb so that, after a search,
# values are setup in the session for this class to work with.
#
# It is normally instantiated in a controller's show action (if save_last_search is called
# in the same controller's index action) and then used in views/utils/_prev_next.html.haml.
#
module Util
  class PrevNext
    attr_reader :curr_id, :prev_id, :next_id, :prev_link, :next_link

    def initialize(session, klass, curr_id, key: klass.to_s.tableize, admin: false)
      @klass   = klass
      @curr_id = curr_id
      @path    = session["last_search_path_#{key}".to_sym]
      @results = session["last_search_list_#{key}".to_sym]
      @admin   = admin
      do_prev
      do_next
    end

    private

    def do_prev
      return unless @results && m = @results.match(/_(page|[1-9]\d*)_#{@curr_id}_/)
      if m[1] == "page"
        return unless @path
        return unless m = @path.match(/page=([2-9]|[1-9]\d+)/)
        @prev_link = @path.sub(/page=[1-9]\d*/, "page=#{m[1].to_i - 1}")
      else
        @prev_link = object(m[1])
        @prev_id = m[1].to_i
      end
    end

    def do_next
      return unless @results && m = @results.match(/_#{@curr_id}_(page|[1-9]\d*)_/)
      if m[1] == "page"
        return unless @path
        m = @path.match(/page=([1-9]\d*)/)
        if m
          @next_link = @path.sub(/page=[1-9]\d*/, "page=#{m[1].to_i + 1}")
        else
          @next_link = @path + (@path.match(/\?/) ? "&" : "?") + "page=2"
        end
      else
        @next_link = object(m[1])
        @next_id = m[1].to_i
      end
    end

    def object(id)
      object = @klass.find(id.to_i) rescue return
      @admin ? [:admin, object] : object
    end
  end
end
