module ICU
  module Legacy
    class Subscription
      include Database

      ONLINE_MAP = {
        sub_id:        nil,
        sub_icu_id:    :player_id,
        sub_season:    :season_desc,
        sub_type:      :category,
        sub_fee:       :cost,
        pay_date:      :created_at,
      }

      OFFLINE_MAP = {
        sof_id:        nil,
        sof_icu_id:    :player_id,
        sof_season:    :season_desc,
        sof_type:      :category,
        sof_fee:       :cost,
        sof_pay_date:  :created_at,
        sof_currency:  nil,
      }

      LIFETIME_MAP = {
        sfl_id:        nil,
        sfl_icu_id:    :player_id,
      }

      def synchronize(force=false)
        if existing_subscriptions?(force)
          report_error "can't synchronize when subscriptions exist unless force is used"
          return
        end

        online_count = 0
        old_database.query(online_sub_query).each do |sub|
          online_count += 1
          create_subscription(sub, ONLINE_MAP)
        end
        puts "old online records processed: #{online_count}"

        offline_count = 0
        old_database.query(offline_sub_query).each do |sub|
          offline_count += 1
          create_subscription(sub, OFFLINE_MAP)
        end
        puts "old offline records processed: #{offline_count}"

        lifetime_count = 0
        old_database.query(lifetime_sub_query).each do |sub|
          lifetime_count += 1
          create_subscription(sub, LIFETIME_MAP)
        end
        puts "old lifetime records processed: #{lifetime_count}"

        puts "new subscription records created: #{::Subscription.count}"
      end

      private

      def create_subscription(old_sub, map)
        new_sub = map.each_with_object({}) do |(old_attr, new_attr), params|
          params[new_attr] = old_sub[old_attr] if new_attr
        end
        id = old_sub[:sub_id] || old_sub[:sof_id] || old_sub[:sfl_id]
        begin
          adjust(new_sub, old_sub)
          subscription = ::Subscription.create!(new_sub)
          puts "#{id} => #{subscription.id}"
        rescue => e
          report_error "could not convert subscription ID #{id}: #{e.message}"
        end
      end

      def adjust(new_sub, old_sub)
        # Work out the category.
        new_sub[:category] = case new_sub[:category]
          when "New U18"    then "new_under_18"
          when "Over 65"    then "over_65"
          when "Overseas"   then "overseas"
          when "Standard"   then "standard"
          when "Under 12"   then "under_12"
          when "Under 18"   then "under_18"
          when "Unemployed" then "unemployed"
          when nil          then "lifetime"
          else raise "unexpected category (#{new_sub[:category]})"
        end
        # Handle a small number of GBP transactions.
        if old_sub[:sof_currency] && old_sub[:sof_currency] != "EUR"
          if old_sub[:sof_currency] == "GBP" && new_sub[:category] == "standard"
            new_sub[:cost] = 35.0
          elsif old_sub[:sof_currency] == "GBP" && new_sub[:category] == "unemployed"
            new_sub[:cost] = 20.0
          else
            raise "can't handle #{old_sub[:sof_currency]} and #{new_sub[:category]}"
          end
        end
        # Handle cost for lifetime subs.
        new_sub[:cost] = 0.0 if new_sub[:category] == "lifetime"
        # Handle missing dates (some offline from 2006 & 2007 and all lifetime).
        if new_sub[:created_at].nil?
          if new_sub[:category] == "lifetime"
            new_sub[:created_at] = case new_sub[:player_id]
              when 276  then Date.new(2000, 9, 1) # Michael Crowe (guess)
              when 687  then Date.new(1998, 9, 1) # Brian Kelly (IM title)
              when 731  then Date.new(2000, 9, 1) # Eamon Keogh (guess)
              when 955  then Date.new(2006, 9, 1) # Gerry Murphy (2006 AGM?)
              when 1350 then Date.new(2008, 9, 1) # Mark Orr (IM title)
              when 1402 then Date.new(2008, 9, 1) # Mark Quinn (IM title)
              when 1535 then Date.new(2000, 9, 1) # Herbert Scarry (guess)
              when 1615 then Date.new(2000, 9, 1) # Brian L. Thorpe (guess)
              when 2042 then Date.new(2006, 9, 1) # Frank Scott (2006 AGM?)
              when 3000 then Date.new(2000, 9, 1) # Kevin J. O'Connell (guess)
              when 4017 then Date.new(2008, 9, 1) # Mark Heidenfeld (IM title)
              when 4564 then Date.new(2012, 9, 1) # Sam E. Collins (IM title)
              when 5157 then Date.new(2011, 9, 1) # Alex Lopez (IM title)
              when 5441 then Date.new(2003, 9, 1) # Gavin Wall (IM title)
              when 6741 then Date.new(2006, 9, 1) # Jack Hennigan (2006 AGM?)
              when 7085 then Date.new(1996, 9, 1) # Alexander Baburin (GM title)
              else raise "unexpected lifetime ICU ID (#{new_sub[:player_id]})"
            end
          else
            start_date = Date.new(2006, 9, 1)
            if old_sub[:sof_id] && old_sub[:sof_id] >= 898 && old_sub[:sof_id] <= 1335
              new_sub[:created_at] = start_date.days_since((395.0 * (old_sub[:sof_id] - 898) / (1335.0 - 898.0)).round)
            else
              raise "unexpected nil for created_at"
            end
          end
        end
        new_sub[:payment_method] = case
          when old_sub[:sub_id] then "paypal"
          when old_sub[:sof_id] then "cheque"
          when old_sub[:sfl_id] then "free"
          else raise "can't determine payment method for ICU ID (#{new_sub[:player_id]})"
        end
        new_sub[:source] = "www1"
      end

      def existing_subscriptions?(force)
        count = ::Subscription.count
        case
        when count == 0
          false
        when force
          puts "old subscription records deleted: #{::Subscription.delete_all}"
          ActiveRecord::Base.connection.execute("ALTER TABLE subscriptions AUTO_INCREMENT = 1")
          false
        else
          true
        end
      end

      def report_error(msg)
        puts "ERROR: #{msg}"
      end

      def online_sub_query
        <<-ONLINE_SUB_QUERY
        SELECT
          #{ONLINE_MAP.keys.join(', ')}
        FROM
          subscriptions,
          payments
        WHERE
          sub_pay_id = pay_id AND
          pay_status IN ('Completed', 'PartRefund')
        ONLINE_SUB_QUERY
      end

      def offline_sub_query
        <<-OFFLINE_SUB_QUERY
        SELECT
          #{OFFLINE_MAP.keys.join(', ')}
        FROM
          subs_offline
        OFFLINE_SUB_QUERY
      end

      def lifetime_sub_query
        <<-LIFETIME_SUB_QUERY
        SELECT
          #{LIFETIME_MAP.keys.join(', ')}
        FROM
          subs_forlife
        LIFETIME_SUB_QUERY
      end
    end
  end
end
