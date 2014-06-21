module ICU
  module Legacy
    class Article
      include Database
      include Utils

      MAP = {
        art_author:  :author,
        art_cat_id:  :category,
        art_date:    :year,
        art_id:      :id,
        art_mem_id:  :user_id,
        art_status:  :active,
        art_text:    :text,
        art_title:   :title,
        art_vis:     :access,
      }

      def synchronize(force=false)
        if existing_articles?(force)
          report_error "can't synchronize when articles/series or article/series journal entries exist unless force is used"
          return
        end

        @bulletins = {}
        [185, 212, 267, 402, 407, 408].each { |id| add_stat(".php (OK)", id) }

        # See concerns/expandable.rb. Avoids validation errors when an article refers to things that don't yet exist.
        ENV["SYNC_ARTICLE"] = "|" + old_database.query("SELECT art_id FROM articles ORDER BY art_id").map{ |r| r[:art_id] }.join("|") + "|"
        ENV["SYNC_NEWS"] = "|739|"

        article_count = 0
        old_database.query("SELECT #{MAP.keys.join(", ")} FROM articles ORDER BY art_id").each do |article|
          article_count += 1
          if [283,322].include?(article[:art_id])
            add_stat("skipped articles", article[:art_id])
          else
            create_article(article)
          end
        end
        puts "old article records processed: #{article_count}"
        puts "new article records created: #{::Article.count}"

        series_count = 0
        series_skipped = 0
        old_database.query("SELECT art_ids FROM article_links").each do |series|
          if create_series(series)
            series_count += 1
          else
            series_skipped += 1
          end
        end
        puts "old series records processed: #{series_count} (skipped: #{series_skipped})"
        puts "new series records created: #{Series.count}"
        puts "new episode records created: #{Episode.count}"

        new_series_count = 0
        @bulletins.each do |season, ids|
          new_series_count += 1
          create_new_series(season, ids)
        end
        puts "new bulletin series created: #{new_series_count}"
        puts "total series records: #{Series.count}"
        puts "total episode records: #{Episode.count}"

        dump_stats
      end

      private

      def create_article(old_article)
        params = MAP.each_with_object({}) do |(old_attr, new_attr), new_article|
          new_article[new_attr] = old_article[old_attr]
        end
        begin
          bulletins(params)
          adjust(params)
          article = ::Article.create!(params)
          gather_article_stats(article)
          puts "created article #{params[:id]}, #{params[:title]}"
        rescue => e
          report_error "could not create article ID #{params[:id]} (#{params[:title]}): #{e.message}"
        end
      end

      def create_series(old_series)
        links = old_series[:art_ids]
        title = links_to_title(links)
        return false unless title
        series = Series.create!(title: title)
        links.scan(/\d+/).map(&:to_i).each do |id|
          Episode.create!(series: series, article_id: id)
        end
        puts "created series #{series.id}, #{title}, #{links}"
        true
      end

      def create_new_series(season, ids)
        title = "ICU Bulletins #{season}"
        articles = ::Article.order(:title).where(id: ids)
        series = Series.create!(title: title)
        articles.each do |article|
          Episode.create!(series: series, article: article)
        end
        puts "created new series #{title}, #{ids.join(', ')}"
      end

      def adjust(params)
        params[:active] = params[:active] == "online"
        params[:markdown] = false
        params[:category] = case params[:category]
          when 1 then "tournament"
          when 2 then "bulletin"
          when 3 then "biography"
          when 4 then "general" # used to be "Game Analysis" but there was only 1
          when 5 then "obituary"
          when 6 then "juniors"
          when 7 then "coaching"
          when 8 then "general"
        end
        params[:access] = case params[:access]
          when "member"        then "members"
          when "editor"        then "editors"
          when "administrator" then "admins"
          else "all"
        end
        params[:year] = params[:year].year
        params[:title].sub!(/\AGarry Kasparov's visit to Ireland 2014 - /, "") if [427, 428, 429, 430].include?(params[:id])
        if [9, 137].include?(params[:id])
          params[:text].gsub!(/\[FEN:[^\]]+\]/) do |fen|
            fen.sub!(/fen=/, "")
            fen.sub!(/size=[^:\]]*/, "")
            fen.sub!(/design=[^:\]]*/, "")
            fen.gsub!(/::+/, ":")
            fen.sub!(/:\]/, "]")
            fen
          end
        end
        convert!(params[:text])
      end

      def gather_article_stats(article)
        add_stat(".php", article.id) if article.text.match(/\.php/)
        add_stat("/misc/ (should be none)", article.id) if article.text.match(/\/misc\//)
        add_stat("mailto (should be none)", article.id) if article.text.match(/mailto\:/)
        add_stat("ART", article.id) if article.text.match(/\[ART:/)
        add_stat("ART:283 (should be none)", article.id) if article.text.match(/\[ART:283/)
        add_stat("FAQ (should be none)", article.id) if article.text.match(/\[FAQ:/)
        add_stat("EVT", article.id) if article.text.match(/\[EVT:/)
        add_stat("GME", article.id) if article.text.match(/\[GME:/)
        add_stat("IMG", article.id) if article.text.match(/\[IMG:/)
        add_stat("IML", article.id) if article.text.match(/\[IML:/)
        add_stat("NWS", article.id) if article.text.match(/\[NWS:/)
        add_stat("PGN", article.id) if article.text.match(/\[PGN:/)
        add_stat("TRN", article.id) if article.text.match(/\[TRN:/)
        add_stat("UPL", article.id) if article.text.match(/\[UPL:/)
      end

      def bulletins(params)
        return unless params[:category] == 2
        if params[:title].match(/\AAGM (20\d\d)/)
          year = $1.to_i - 1
        elsif params[:title].match(/\AEGM (2005)/)
          year = $1.to_i - 1
        else
          year = params[:year].year
          month = params[:year].month
          year -= 1 if month < 9
        end
        season = "#{year}-#{(year + 1).to_s[2,2]}"
        @bulletins[season] ||= []
        @bulletins[season].push(params[:id])
      end

      def links_to_title(links)
        @title_number ||= 0
        @title_number += 1
        case links
        when "|101|106|110|108|109|107|" then nil # "2006 AGM"
        when "|123|124|149|"             then "Ireland-Sussex Junior Matches"
        when "|172|316|"                 then "Rating Foreign Tournaments"
        when "|173|183|195|200|201|"     then "Rating Officer Reports 2008"
        when "|215|260|"                 then "Ireland at the Olympiads"
        when "|218|227|232|233|"         then "Rating Officer Reports 2009"
        when "|242|257|273|274|"         then "Rating Officer Reports 2010"
        when "|261|270|271|"             then "Dun Laoghaire 2010"
        when "|280|279|281|282|"         then "Khanty Mansiysk 2010"
        when "|290|307|323|324|"         then "Rating Officer Reports 2011"
        when "|305|306|375|"             then "ICU Instructors"
        when "|30|31|"                   then "Hugh Alexander"
        when "|338|350|358|359|"         then "Rating Officer Reports 2012"
        when "|34|32|"                   then "Alexander Baburin"
        when "|35|36|"                   then "Austin Bourke"
        when "|3|193|"                   then "ICU Ratings"
        when "|407|408|434|440|439|441|" then "History of Kilkenny Chess Club"
        when "|426|427|428|430|429|"     then "Kasparov's Visit to Ireland 2014"
        when "|44|45|"                   then "Paddy Duignan"
        when "|50|51|"                   then "Paddy Kennedy"
        when "|54|55|"                   then "Hugh MacGrillen"
        when "|67|68|69|"                then "Barney O'Sullivan"
        when "|6|14|15|16|20|26|25|"     then nil # "AGM 2005"
        when "|73|74|"                   then "Enda Rohan"
        when "|7|12|"                    then nil # "UCU Split"
        when "|88|89|"                   then nil # "ISC Reports 2006"
        else "Untitled Series #{@title_number}"
        end
      end

      def existing_articles?(force)
        count = ::Article.count
        changes = JournalEntry.articles.count
        series_count = Series.count
        series_changes = JournalEntry.series.count
        episode_count = Episode.count
        case
        when count == 0 && changes == 0 && series_count == 0 && series_changes == 0 && episode_count == 0
          false
        when force
          puts "old article records deleted: #{::Article.delete_all}"
          puts "old article journal entries deleted: #{JournalEntry.articles.delete_all}"
          puts "old series records deleted: #{Series.delete_all}"
          puts "old series journal entries deleted: #{JournalEntry.series.delete_all}"
          puts "old episode records deleted: #{Episode.delete_all}"
          ActiveRecord::Base.connection.execute("ALTER TABLE series AUTO_INCREMENT = 1")
          ActiveRecord::Base.connection.execute("ALTER TABLE episodes AUTO_INCREMENT = 1")
          false
        else
          true
        end
      end
    end
  end
end
