module ICU
  module Legacy
    module Database
      def old_database
        return @database if @database
        @database = Mysql2::Client.new(APP_CONFIG["legacy_db"].symbolize_keys)
        @database.query_options.merge!(symbolize_keys: true)
        @database
      end
    end
  end
end
  