module ICU
  module Legacy
    module Database
      def old_database
        return @old if @old
        @old = Mysql2::Client.new(APP_CONFIG["legacy_db"].symbolize_keys)
        @old.query_options.merge!(symbolize_keys: true)
        @old
      end

      def rat_database
        return @rat if @rat
        @rat = Mysql2::Client.new(APP_CONFIG["ratings_db"].symbolize_keys)
        @rat.query_options.merge!(symbolize_keys: true)
        @rat
      end
      
      def any_database
      end
    end
  end
end
  