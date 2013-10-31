module ICU
  module Legacy
    class Check
      def check
        check_duplicate_players
        check_user_players
        check_club_players
      end

      private

      def check_duplicate_players
        @player = ::Player.all.each_with_object({}) do |player, hash|
          hash[player.id] = player
        end

        self_duplicates = @player.each_with_object([]) do |(id, player), duplicates|
          duplicates << id if player.player_id == id
        end
        report("Players with self duplicates", self_duplicates)

        invalid_duplicates = @player.each_with_object([]) do |(id, player), invalids|
          invalids << id if player.player_id && !@player[player.player_id]
        end
        report("Players with invalid duplicates", invalid_duplicates)

        active_duplicates = @player.each_with_object([]) do |(id, player), actives|
          actives << id if player.player_id && player.status == "active"
        end
        report("Duplicates with active status", active_duplicates)
      end

      def check_user_players
        @user = ::User.all.each_with_object({}) do |user, hash|
          hash[user.id] = user
        end

        missing_players = @user.each_with_object([]) do |(id, user), missing|
          missing << id if user.player_id.blank?
        end
        report("Users with missing player", missing_players)

        invalid_players = @user.each_with_object([]) do |(id, user), invalids|
          invalids << id if user.player_id && !@player[user.player_id]
        end
        report("Users with invalid player", invalid_players)
      end

      def check_club_players
        @club = ::Club.all.each_with_object({}) do |club, hash|
          hash[club.id] = club
        end

        invalid_clubs = @player.each_with_object([]) do |(id, player), invalids|
          invalids << id if player.club_id && !@club[player.club_id]
        end
        report("Players with invalid club", invalid_clubs)
      end

      def report(topic, ids)
        if ids.any?
          message = "#{topic} (#{ids.size}): "
          if ids.size > 20
            ids = ids[0,10] << "..." << ids[-10,10]
          end
          message << ids.join(",")
          puts message
        else
          puts "#{topic}: none"
        end
      end
    end
  end
end
