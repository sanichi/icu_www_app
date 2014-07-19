module ICU
  module Legacy
    class Tournament
      include Database
      include Utils

      MAP = {
        trn_id:      :id,
        trn_title:   :name,
        trn_city:    :city,
        trn_year:    :year,
        trn_type_id: :format,
        trn_cat_id:  :category,
        trn_details: :details,
        trn_status:  :active,
      }

      def synchronize(force=false)
        if existing_tournaments?(force)
          report_error "can't synchronize when tournaments or tournament journal entries exist unless force is used"
          return
        end
        tournament_count = 0
        skipped_tournaments = 0
        @links = {}
        old_database.query("SELECT #{MAP.keys.join(", ")} FROM tournaments").each do |tournament|
          tournament_count += 1
          if [105, 113, 115, 116, 117].include?(tournament[:trn_id])
            skipped_tournaments += 1
          else
            create_tournament(tournament)
          end
        end
        puts "old tournament records processed: #{tournament_count}"
        puts "new tournament records created: #{::Tournament.count}"
        puts "skipped tournaments: #{skipped_tournaments}"
        puts "links:"
        @links.each do |type, ids|
          puts "  #{type}: #{ids.join(', ')}"
        end
      end

      private

      def create_tournament(old_tournament)
        params = MAP.each_with_object({}) do |(old_attr, new_attr), new_tournament|
          new_tournament[new_attr] = old_tournament[old_attr]
        end
        begin
          adjust(params)
          links(params)
          correct(params)
          ::Tournament.create!(params)
          puts "created tournament #{params[:id]}, #{params[:name]}"
        rescue => e
          report_error "could not create tournament ID #{params[:id]} (#{params[:name]}): #{e.message}"
        end
      end

      def adjust(params)
        params[:active] = params[:active] == "online"
        params[:category] = case params[:category]
        when 1  then "open"
        when 2  then "championship"
        when 3  then "junior"
        when 4  then "veteran"
        when 8  then "section"
        when 7  then "blind"
        when 9  then "international"
        when 10 then "grand_prix"
        end
        params[:format] = case params[:format]
        when 1 then "swiss"
        when 2 then "rr"
        when 3 then "knockout"
        when 4 then "swiss_teams"
        when 5 then "match"
        when 6 then "schev"
        when 7 then "grand_prix"
        when 8 then "simul"
        end
        if [372, 468, 470, 471].include?(params[:id])
          params[:details].gsub!(/&gt;/, ">")
          params[:details].gsub!(/&lt;/, "<")
        end
      end

      def correct(params)
        params[:category] = "junior"  if params[:name].match(/junior/i) && params[:name].match(/u(nder)\s?\d/i)
        params[:category] = "section" if [2, 14, 562].include?(params[:id])
        params[:category] = "open"    if params[:id] == 13
        if params[:id] == 199
          params[:details].sub!(/\n/, "\n[DLD:141:PGN]\n")
        end
        if params[:id] == 468
          params[:details].sub!(/\n/, "\n[DLD:142:PGN]\n")
        end
        if params[:id] == 566
          params[:details].sub!(/\n/, "\n[DLD:144:PGN]\n")
        end
        if params[:id] == 605
          params[:details].markoff!
          params[:details].sub! /\A\s*HQBHMLBACR/, "                           H Q B H M L B A C R"
          params[:details].sub! /^Lopez, Alex \(IRL\)/, "Lopez, Alex (IRL) "
          params[:details].sub! /^Rochev, Yury \(RUS\)/, "Rochev, Yury (RUS) "
          params[:details].gsub! /\]/, "] "
          params[:details].gsub! /\*/, "* "
          params[:details].gsub! /\)/, ") "
        end
        if params[:id] == 606
          params[:details].markoff!
          params[:details].sub! /\A\s*ALCBDFTMSG/, "                                   A L C B D F T M S G"
          params[:details].gsub! /\]/, "] "
          params[:details].gsub! /\*/, "* "
        end
      end

      def links(params)
        params[:details].gsub!(/<a\s+[^<]+<\/a>/i) do |str|
          m = str.match(/\A<a\s+href="(?<href>[^"]+)"\s*>(?<text>[^<]+)<\/a>\z/i)
          if m[:href] && m[:text]
            if m[:href].match(/\A\/misc/)
              count_link("downloads", params[:id])
              download_link(m[:href], m[:text])
            elsif m[:href].match(/\A\/(articles|games|images|tournaments)\/display\.php\?id=([1-9]\d*)\z/)
              count_link($1, params[:id])
              generic_link($1, $2, m[:text])
            else
              raise "don't know how to convert link: #{m}"
            end
          else
            raise "can't extract href and text from link: #{m}"
          end
        end
      end

      def download_link(href, text)
        download = ::Download.find_by(www1_path: href)
        if download
          "[DLD:#{download.id}:#{text}]"
        else
          raise "can't find download for path: #{href}"
        end
      end

      def generic_link(type, id, text)
        code = case type
        when "articles"    then "ART"
        when "images"      then "IML"
        when "games"       then "PGN"
        when "tournaments" then "TRN"
        when "downloads"   then "DLD"
        else raise "invalid generic link type: #{type}"
        end
        "[#{code}:#{id}:#{text}]"
      end

      def count_link(type, id)
        @links[type] = [] unless @links[type]
        @links[type].push id unless @links[type].include?(id)
      end

      def existing_tournaments?(force)
        count = ::Tournament.count
        changes = JournalEntry.tournaments.count
        case
        when count == 0 && changes == 0
          false
        when force
          puts "old tournament records deleted: #{::Tournament.delete_all}"
          puts "old tournament journal entries deleted: #{JournalEntry.tournaments.delete_all}"
          false
        else
          true
        end
      end
    end
  end
end
