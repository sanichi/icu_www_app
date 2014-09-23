module ICU
  module Legacy
    module Utils
      def report_error(msg)
        puts "ERROR: #{msg}"
      end

      def add_stat(key, id)
        @stats ||= Hash.new { Array.new }
        @stats[key] = @stats[key] << id
      end

      def dump_stats
        max = @stats.keys.inject(0) { |m, k| m = k.length if k.length > m; m }
        puts "stats:"
        @stats.keys.sort.each do |name|
          ids = @stats[name]
          size = ids.size
          ids = ids.sort
          ids = ids.sort[0,10] << "..." << ids[-10,10] if size > 20
          puts "  %-#{max}s %5d: %s" % [name, size, ids.join(',')]
        end
      end

      def convert!(text)
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/articles\/display\.php\?id=(\d+)(?:#[^"]+)?">([^<]+)<\/a>/i) { %Q{[ART:#{$1}:#{$2}]} }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/events\/display\.php\?id=(\d+)">([^<]+)<\/a>/i) { %Q{[EVT:#{$1}:#{$2}]} }
        text.gsub!(/>\s*<a\s+href=["'](?:http:\/\/(?:www\.)?icu\.ie)?\/games\/display\.php\?id=(\d+)["']>([^<]+)<\/a>\s*</i) { %Q{>[GME:#{$1}:#{$2}]<} }
        text.gsub!(/<a\s+href=["'](?:http:\/\/(?:www\.)?icu\.ie)?\/games\/display\.php\?id=(\d+)["']>([^<]+)<\/a>/i) { %Q{[GME:#{$1}:#{$2}]} }
        text.gsub!(/<a\s+href=["'](?:http:\/\/(?:www\.)?icu\.ie)?\/images\/display\.php\?id=(\d+)["']>([^<]+)<\/a>/i) { %Q{[IML:#{$1}:#{$2}]} }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/news\/display\.php\?id=(\d+)">([^<]+)<\/a>/i) { %Q{[NWS:#{$1}:#{$2}]} }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/tournaments\/display\.php\?id=(\d+)">([^<]+)<\/a>/i) { %Q{[TRN:#{$1}:#{$2}]} }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/articles\/list\.php\?title=([^&]+)">([^<]+)<\/a>/i) do
          %Q{<a href="/articles?title=#{$1}">#{$2}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/articles\/list\.php">([^<]+)<\/a>/i) do
          %Q{<a href="/articles">#{$1}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/articles\/list\.php\?title=([^&]+)&cat_id=2">([^<]+)<\/a>/i) do
          %Q{<a href="/articles?title=#{$1}&category=bulletin">#{$2}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/articles\/list\.php\?cat_id=3(?:&order=[^&]+)?">([^<]+)<\/a>/i) do
          %Q{<a href="/articles?category=biography">#{$1}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/clubs\/list\.php">([^<]+)<\/a>/i) do
          %Q{<a href="/clubs">#{$1}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/clubs\/list\.php\?filter=([^&]+)">([^<]+)<\/a>/i) do
          %Q{<a href="/clubs?name=#{$1}">#{$2}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/events\/(?:list|index)\.php">([^<]+)<\/a>/i) do
          %Q{<a href="/events">#{$1}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/events\/list\.php\?type=irish">([^<]+)<\/a>/i) do
          %Q{<a href="/events?category=irish">#{$1}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/games\/list\.php\?date=([^&]+)&event=([^&]+)(?:&order=[^&]+)?">([^<]+)<\/a>/i) do
          %Q{<a href="/games?date=#{$1}&event=#{$2}">#{$3}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/games\/list\.php\?event=([^&]+)&date=([^&]+)(?:&order=[^&]+)?">([^<]+)<\/a>/i) do
          %Q{<a href="/games?date=#{$2}&event=#{$1}">#{$3}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/games\/list\.php\?event=([^&]+)(?:&order=[^&]+)?">([^<]+)<\/a>/i) do
          %Q{<a href="/games?event=#{$1}">#{$2}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/images\/list\.php">([^<]+)<\/a>/i) do
          %Q{<a href="/images"</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/images\/list\.php\?text=([^"]+)(?:\+|%20)(\d{4})">([^<]+)<\/a>/i) do
          %Q{<a href="/images?caption=#{$1}&year=#{$2}">#{$3}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/images\/list\.php\?(?:page=\d+&)?text=([^&]+)(?:\+|%20)(\d{4})">([^<]+)<\/a>/i) do
          %Q{<a href="/images?caption=#{$1}&year=#{$2}">#{$3}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/images\/list\.php\?text=([^&]+)(?:\+|%20)(\d{4})(?:&psize=\d+)?(?:&page=\d+)?">([^<]+)<\/a>/i) do
          %Q{<a href="/images?caption=#{$1}&year=#{$2}">#{$3}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/images\/list\.php\?text=([^&]+)(?:&psize=\d+)?(?:&page=\d+)?">([^<]+)<\/a>/i) do
          caption, label = $1, $2
          if caption == "Kevin+Connell"
            caption = "Kevin+O%27Connell"
            if label == "more"
              label = "More pictures"
            end
          end
          %Q{<a href="/images?caption=#{caption}">#{label}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/tournaments\/list\.php\?title=([^&]+)">([^<]+)<\/a>/i) do
          %Q{<a href="/tournaments?name=#{$1}">#{$2}</a>}
        end
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/faqs\/(?:[^"]*)">([^<]+)<\/a>/i) { $1 }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/icj\/(?:[^"]*)">([^<]+)<\/a>/i) { $1 }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/icu\/(?:\w+)\.php(?:[^"]*)">([^<]+)<\/a>/i) { $1 }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/index\.php(?:[^"]*)">([^<]+)<\/a>/i) { $1 }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/juniors\/index\.php(?:[^"]*)">([^<]+)<\/a>/i) { $1 }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/maps\/display\.php(?:[^"]*)">([^<]+)<\/a>/i) { $1 }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/members\/(?:register|newbies)\.php(?:[^"]*)">([^<]+)<\/a>/i) { $1 }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/ratings\/(?:\w+)\.php(?:[^"]*)">([^<]+)<\/a>/i) { $1 }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/tournaments\/champs_list\.php(?:[^"]*)">([^<]+)<\/a>/i) { $1 }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/votes\/(?:[^"]*)">([^<]+)<\/a>/i) { $1 }

        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/members\/login\.php">([^<]+)<\/a>/i) { %Q{<a href="/sign_in">#{$1}</a>} }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/tournaments\/index\.php">([^<]+)<\/a>/i) { %Q{<a href="/tournaments">#{$1}</a>} }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/shop\/(?:\w+)\.php">([^<]+)<\/a>/i) { %Q{<a href="/shop">#{$1}</a>} }
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?\/shop\/buy_item\.php\?type=[A-Z]{3}">([^<]+)<\/a>/i) { %Q{<a href="/shop">#{$1}</a>} }
        text.gsub!(/<b><\/b>/, "")
        text.gsub!(/<a\s+href="(?:http:\/\/(?:www\.)?icu\.ie)?(\/misc\/[^"]+)"(?:\s+target="[^"]+")?>([^<]+)<\/a>/i) do
          download = Download.where(www1_path: $1).first
          if download
            %Q{[DLD:#{download.id}:#{$2}]}
          else
            "Error (#{$1}|#{$2})"
          end
        end
        text.gsub!(/<a\s+href=["']mailto:([^"']+)["']>([^<]+)<\/a>/i) do
          "[EMA:#{$1}:#{$2}]"
        end
      end
    end
  end
end
