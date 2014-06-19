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
    end
  end
end
