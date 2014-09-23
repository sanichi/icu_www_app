module ICU
  class PGN
    def database(force)
      count = get_count || return
      last_mod = get_last_mod(count, force) || return
      compile_pgn
      compress_zip
    rescue => e
      # For the cron log.
      puts "#{signature}: #{count}, #{last_mod}, #{e.class}, #{e.message}\n#{e.backtrace[0..3].join("\n")}"
      # To notify the webmaster.
      ::Failure.log(signature(true), exception: e, time: time, count: count, last_mod: last_mod)
    end

    private

    def compress_zip
      cmd = "gzip -q -c #{pgn_file} > #{zip_file}"
      if system(cmd)
        pgn_size = File.size(pgn_file) rescue 0
        zip_size = File.size(zip_file) rescue 0
        puts "#{signature}: compressed PGN (#{pgn_size.to_s(:human_size)}) to ZIP (#{zip_size.to_s(:human_size)})"
      else
        raise "system call (#{cmd}) falied"
      end
    end

    def compile_pgn
      start = Time.now.to_f
      File.open(pgn_file, "w") do |f|
        Game.find_each do |g|
          f.write g.to_pgn
        end
      end
      seconds = (Time.now.to_f - start).round(2)
      puts "#{signature}: generated PGN in #{seconds} seconds"
    end

    def get_last_mod(new_count, force)
      new_last_mod = Game.maximum(:updated_at).to_s(:db)

      # Do we need to regenerate the file?
      unless force || !File.exist?(zip_file)
        old_last_mod, old_count = ::Game.get_last_pgn_db
        if old_last_mod.present? && old_last_mod == new_last_mod
          puts "#{signature}: last game modified time (#{old_last_mod}) has not changed"
          return false
        end
      end

      # Log the last modified time and count.
      ::Game.save_last_pgn_db(new_last_mod, new_count)

      # Return the last modified time.
      new_last_mod
    end

    def get_count
      count = ::Game.count
      if count > 0
        count
      else
        puts "#{signature}: no games"
        false
      end
    end

    def pgn_file
      ::Game::PGN_FILE
    end

    def zip_file
      ::Game::ZIP_FILE
    end

    def signature(exception=false)
      exception ? "ICUPGNDatabase" : "ICU::PGN#database #{time}"
    end

    def time
      Time.now.utc.to_s(:db)
    end
  end
end
