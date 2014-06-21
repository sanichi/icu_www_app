module ICU
  module Legacy
    class News
      include Database
      include Utils

      MAP = {
        news_date:    :date,
        news_id:      :id,
        news_mem_id:  :user_id,
        news_status:  :active,
        news_summary: :summary,
        news_title:   :headline,
      }

      def synchronize(force=false)
        if existing_news?(force)
          report_error "can't synchronize when news or news journal entries exist unless force is used"
          return
        end

        [100, 280, 304, 359, 364, 421, 452, 548, 607, 678, 821, 843, 1016].each { |id| add_stat(".php OK", id) }

        news_count = 0
        old_database.query("SELECT #{MAP.keys.join(", ")} FROM news ORDER BY news_id").each do |news|
          news_count += 1
          if [227, 520, 521, 522].include?(news[:news_id])
            add_stat("skipped news items", news[:news_id])
          else
            create_news(news)
          end
        end
        puts "old news records processed: #{news_count}"
        puts "new news records created: #{::News.count}"

        dump_stats
      end

      private

      def create_news(old_news)
        params = MAP.each_with_object({}) do |(old_attr, new_attr), new_news|
          new_news[new_attr] = old_news[old_attr]
        end
        begin
          adjust(params)
          news = ::News.create!(params)
          gather_news_stats(news)
          puts "created news #{params[:id]}, #{params[:headline]}"
        rescue => e
          report_error "could not create news ID #{params[:id]} (#{params[:title]}): #{e.message}"
        end
      end

      def adjust(params)
        params[:active] = params[:active] == "online"
        params[:created_at] = params[:date].to_time
        convert!(params[:summary])
        mark_down!(params[:summary], params[:id])
        if params[:id] == 498
          params[:summary].sub!(/<table>/, %q{<table class="blank">})
        end
      end

      def gather_news_stats(news)
        add_stat(".php", news.id) if news.summary.match(/\.php/)
        add_stat("/misc/ (should be none)", news.id) if news.summary.match(/\/misc\//)
        add_stat("mailto (should be none)", news.id) if news.summary.match(/mailto\:/)
        add_stat("ART", news.id) if news.summary.match(/\[ART:/)
        add_stat("ART:283 (should be none)", news.id) if news.summary.match(/\[ART:283/)
        add_stat("FAQ (should be none)", news.id) if news.summary.match(/\[FAQ:/)
        add_stat("EVT", news.id) if news.summary.match(/\[EVT:/)
        add_stat("FEN", news.id) if news.summary.match(/\[FEN:(?!fen=)/)
        add_stat("FEN:fen= (should be none)", news.id) if news.summary.match(/\[FEN:fen=/)
        add_stat("GME", news.id) if news.summary.match(/\[GME:/)
        add_stat("IMG", news.id) if news.summary.match(/\[IMG:/)
        add_stat("IML", news.id) if news.summary.match(/\[IML:/)
        add_stat("NWS", news.id) if news.summary.match(/\[NWS:/)
        add_stat("PGN", news.id) if news.summary.match(/\[PGN:/)
        add_stat("TRN", news.id) if news.summary.match(/\[TRN:/)
        add_stat("UPL", news.id) if news.summary.match(/\[UPL:/)
        add_stat("<p> (should be none)", news.id) if news.summary.match(/<\/?p[ >]/i)
        add_stat("<em> (should be none)", news.id) if news.summary.match(/<\/?em[ >]/i)
        add_stat("<i> (should be none)", news.id) if news.summary.match(/<\/?i[ >]/i)
        add_stat("<b> (should be none)", news.id) if news.summary.match(/<\/?b[ >]/i)
        add_stat("<strong> (should be none)", news.id) if news.summary.match(/<\/?strong[ >]/i)
        add_stat("<ol> (should be none)", news.id) if news.summary.match(/<\/?ol[ >]/i)
        add_stat("<ul> (should be none)", news.id) if news.summary.match(/<\/?ul[ >]/i)
        add_stat("<ul><ul> (should be none)", news.id) if news.summary.match(/<ul>.*<ul>/im)
        add_stat("<li> (should be none)", news.id) if news.summary.match(/<\/?li[ >]/i)
        add_stat("<dl>", news.id) if news.summary.match(/<\/?dl[ >]/i)
        add_stat("<dt>", news.id) if news.summary.match(/<\/?dt[ >]/i)
        add_stat("<dd>", news.id) if news.summary.match(/<\/?dd[ >]/i)
        add_stat("<table>", news.id) if news.summary.match(/<\/?table[ >]/i)
        add_stat("<tr>", news.id) if news.summary.match(/<\/?tr[ >]/i)
        add_stat("<td>", news.id) if news.summary.match(/<\/?td[ >]/i)
        add_stat("<th>", news.id) if news.summary.match(/<\/?th[ >]/i)
        add_stat("<div> (should be none)", news.id) if news.summary.match(/<\/?div[ >]/i)
        add_stat("<h> (should be none)", news.id) if news.summary.match(/(<\/?h[ >]|^#+)/i)
      end

      def existing_news?(force)
        count = ::News.count
        changes = JournalEntry.news.count
        case
        when count == 0 && changes == 0
          false
        when force
          puts "old news records deleted: #{::News.delete_all}"
          puts "old news journal entries deleted: #{JournalEntry.news.delete_all}"
          false
        else
          true
        end
      end

      def mark_down!(text, id)
        text.gsub!(/\t/, " ")   # no tabs
        text.gsub!(/\r/, "")    # no carriage returns
        text.gsub!(/^[ ]+/, "") # no leading spaces
        text.gsub!(/[ ]+$/, "") # no training spaces

        text.gsub!(/<a\s+href="([^"]+)">([^<]+)<\/a>/i) { "[#{$2}](#{$1})" }  # <a>
        text.gsub!(/<b>([^<]+)<\/b>/i)                  { "**#{$1}**" }       # <b>
        text.gsub!(/<em>([^<]+)<\/em>/i)                { "*#{$1}*" }         # <em>
        text.gsub!(/<i>([^<]+)<\/i>/i)                  { "*#{$1}*" }         # <i>

        text.gsub!(/<div\s+style="clear:\s*both"><\/div>/i, "\n\n")  # don't seem to need these any more
        text.gsub!(/<div\s+style="[^"]+">/i, "\n\n")                 # can get away without these
        text.gsub!(/<\/div>/i, "\n\n")                               # can get away without these

        text.sub!(/\A\s*<p>\s*/i, "")                # start of initial paragraphs
        text.sub!(/\s*<\/p>\s*\z/i, "\n")            # end of last paragraphs

        text.gsub!(/\s*<\/p>\s*<p>\s*/i, "\n\n")     # end and start of a paragraph
        text.gsub!(/\s*<p>\s*/i, "\n\n")             # start of any other paragraph
        text.gsub!(/\s*<\/p>\s*/i, "\n\n")           # end of any other paragraph
        text.gsub!(/\s*<p\/>\s*/i, "\n\n")           # buggy markup

        # text.gsub!(/\s*<\/?dl>\s*/i, "\n\n")                          # get rid of <dl>
        # text.gsub!(/\s*<dt>([^<]+)<\/dt>\s*/i) { "\n\n**#{$1}**\n\n"} # replace <dt>
        # text.gsub!(/\s*<dd>([^<]+)<\/dd>\s*/i) { "\n\n#{$1}\n\n"}     # replace <dd>

        text.gsub!(/^<\/?ol>\s*/i, "\n\n") # remove <ol> list start/end (912)
        text.gsub!(/^<\/?ul>\s*/i, "\n\n") # remove <ul> list start/end (14,74,111,256,258,282,310,539,554,577,646,759,834,882,887,938,993,1050)
        if id == 912
          text.gsub!(/^<li>([^<]+)<\/li>/i) { " 1. #{$1.trim}" } # <li> (ol)
        else
          text.gsub!(/^<li>([^<]+)<\/li>/i) { " - #{$1.trim}" } # <li> (ul)
        end

        text.gsub!(/\[FEN:fen=/, "[FEN:") # correct FEN syntax

        text.gsub!(/\n\n\n+/, "\n\n")                        # too many newlines anywhere
        text.sub!(/\n\n+\z/, "\n")                           # too many newlines at the end
        text.gsub!(/([^\s>])\n([^\s<])/) { "#{$1} #{$2}" }   # merge single newlines
        text.gsub!(/  +/, " ")                               # squash 2 or more spaces
        text.gsub!(/\( +/, "(")                              # no spaces after opening brackets
        text.gsub!(/ +\)/, ")")                              # no spaces before closing brackets
        text.gsub!(/[‘’]/, "'")                              # typewriter single quotes
        text.gsub!(/[“”]/, '"')                              # typewriter double quotes

        # help with table display (e.g. with news ID 498, 512)
        text.gsub!(/<\/table>\n<\/td>\n<\/tr>/, "</table></td></tr>")
        text.gsub!(/<\/table>\n<\/td>\n<td>\n<table>/, "</table></td>\n<td><table>")
        text.gsub!(/class=["']tableheader["']/, %q{class="text-center"})
      end
    end
  end
end
