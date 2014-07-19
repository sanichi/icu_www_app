module ICU
  module Legacy
    class Download
      include Utils
      #
      # Unusually, this sync does not involve the legacy database. Instead we are synchronizing a bunch of www1
      # files (whose location on the lagacy server was prd/htd/misc) with a new database table called downloads.
      # In www1 the files were uploaded via FTP, but in www2 they will be uploaded via HTTP and also create rows
      # in the new table.
      #
      # To enable this sync to work, you need to first copy the files to tmp/www1/misc.
      #
      def synchronize(force)
        if existing_downloads?(force)
          report_error "can't synchronize when downloads or download journal entries exist unless force is used"
          return
        end
        return unless chdir
        synced, skipped = 0, 0
        Dir.glob("**/*") do |name|
          if File.file?(name)
            www1_path = "/misc/#{name}"
            description, year, access = guess(name)
            if description && year && access
              begin
                params = { description: description, year: year, access: access, user_id: 1, www1_path: www1_path }
                case name
                when /\.xlsx\z/ then params[:data] = Rack::Test::UploadedFile.new(name, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
                when /\.docx\z/ then params[:data] = Rack::Test::UploadedFile.new(name, "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
                else params[:data] = File.new(name)
                end
                ::Download.create!(params)
                puts "created download for #{www1_path}"
                synced += 1
              rescue => e
                report_error "couldn't save #{name}: #{e.message}"
                skipped += 1
              end
            else
              missing = []
              missing.push "description" unless description
              missing.push "year" unless year
              missing.push "access" unless access
              report_error "missing #{missing.join(', ')} for #{www1_path}"
              skipped += 1
            end
          end
        end
        puts "files synced:  #{synced}"
        puts "files skipped: #{skipped}"
      end

      private

      def existing_downloads?(force)
        count = ::Download.count
        changes = JournalEntry.downloads.count
        case
        when count == 0 && changes == 0
          false
        when force
          puts "old download records deleted: #{::Download.delete_all}"
          puts "old download journal entries deleted: #{JournalEntry.downloads.delete_all}"
          ActiveRecord::Base.connection.execute("ALTER TABLE downloads AUTO_INCREMENT = 1")
          remove_old_files
          false
        else
          true
        end
      end

      def remove_old_files
        path = Rails.root + "public" + "system" + "downloads"
        FileUtils.remove_dir(path) if File.directory?(path)
      end

      def chdir
        path = Rails.root + "tmp" + "www1" + "misc"
        Dir.chdir(path)
        puts "successfully changed directory to to #{path}"
        true
      rescue
        report_error "can't change directory to to #{path}"
        false
      end

      def guess(name)
        description, year, access = nil, nil, "all"
        case name
        when /\Aagm\/20(\d\d)\/minutes.doc\z/
          description = "Minutes of the 20#{$1} AGM"
          year = "20#{$1}".to_i
        when "agm/2005/egm_minutes.doc"
          description = "Notice of EGM prior to 2005 AGM"
          year = 2005
        when "agm/2005/notice.doc"
          description = "Agenda for the 2005 AGM"
          year = 2005
        when "agm/2005/officer_reports.doc"
          description = "Officer reports, AGM 2005"
          year = 2005
        when "agm/2005/proposal.doc"
          description = "Proposal to change constitution, AGM 2005"
          year = 2005
        when /\Aagm\/2005\/reports\/((membership|rating)_officer|secretary|treasurer).(doc|pdf)\z/
          description = "Report of the #{$1.humanize.titleize}, AGM 2005"
          year = 2005
        when "agm/2005/reports/treasurer.xls"
          description = "Financial report, AGM 2005"
          year = 2005
          access = "members"
        when "agm/2009/treasurer.doc"
          description = "Report of the Treasurer, AGM 2009"
          year = 2009
        when "agm/2010/minutes.pdf"
          description = "Minutes of the AGM, 2010"
          year = 2010
        when "agm/2010/motions.doc"
          description = "Motions for the 2010 AGM"
          year = 2010
        when "agm/2011/development_officer.pdf"
          description = "Report of the Development Officer, AGM 2011"
          year = 2011
        when "agm/2011/fide_delegate.pdf"
          description = "Report of the FIDE Delegate, AGM 2011"
          year = 2011
        when "agm/2011/treasurer.pdf"
          description = "Report of the Treasurer, AGM 2011"
          year = 2011
        when "agm/2011/treasurer.xlsx"
          description = "Financial accounts, AGM 2011"
          year = 2011
          access = "members"
        when "agm/2011/vice_chairperson.pdf"
          description = "Report of the Vice Chairperson, AGM 2011"
          year = 2011
        when "agm/2012/accounts_2011-12.pdf"
          description = "Financial accounts, AGM 2012"
          year = 2012
          access = "members"
        when "agm/2012/john_alfred_flier.pdf"
          description = "John Alfred flyer, running for chairman, AGM 2012"
          year = 2012
        when /\Aagm\/2013\/accounts_part_([1-5])_of_5\.pdf\z/
          description = "Financial accounts, part #{$1} of 5, AGM 2013"
          year = 2013
          access = "members"
        when "agm/2013/code_of_conduct.pdf"
          description = "Code of conduct, AGM 2013"
          year = 2013
          access = "members"
        when "agm/2013/disciplinary_rules.pdf"
          description = "Disciplinary rules, AGM 2013"
          year = 2013
          access = "members"
        when "agm/2013/proposed_amendments.pdf"
          description = "Proposed amendments to the constitution, AGM 2013"
          year = 2013
          access = "members"
        when "audio/charles.wav"
          description = "Eamon Keogh sound bite \"Oh Charles\""
          year = 2006
        when "audio/mister.wav"
          description = "Eamon Keogh sound bite \"Well f@*! ya mister\""
          year = 2006
        when "bulletins/ISC_2010.pdf"
          description = "International Selection Committee, report, July 2010"
          year = 2010
        when "bulletins/ISC_2010_1.doc"
          description = "International Selection Committee, bulletin, August 2010"
          year = 2010
        when "bulletins/ISC_2011.pdf"
          description = "International Selection Committee, report, 2011"
          year = 2011
        when "bulletins/ISC_2012.pdf"
          description = "International Selection Committee, report, June 2012"
          year = 2012
        when "bulletins/ISC_2012_06_21.pdf"
          description = "International Selection Committee, update, June 2012"
          year = 2012
        when "bulletins/ISC_BritishChamps_2011.pdf"
          description = "International Selection Committee, Bristish Championships recommendation, 2011"
          year = 2011
        when "bulletins/ISC_EYCC_2012.pdf"
          description = "International Selection Committee, European Youth Chess Championship, May 2012"
          year = 2012
        when "bulletins/JSC_2013_04.pdf"
          description = "Junior Selection Committee, report, April 2013"
          year = 2013
        when "bulletins/JSC_2013_06.pdf"
          description = "Junior Selection Committee, report, May 2013"
          year = 2013
        when "bulletins/JSC_2013_08.pdf"
          description = "Junior Selection Committee, report, August 2013"
          year = 2013
        when "bulletins/JSC_2014_05.pdf"
          description = "Junior Selection Committee, report, May 2014"
          year = 2014
        when "bulletins/kasparov_2014_en.pdf"
          description = "Garry Kasparov, press release, March 2014"
          year = 2014
        when "bulletins/kasparov_2014_ga.pdf"
          description = "Garry Kasparov, press release, March 2014 (Irish)"
          year = 2014
        when "cc08.pdf"
          description = "Cork Congress 2008"
          year = 2008
        when "coaching/Baburin_workshop_09.pdf"
          description = "Master class by GM Baburin, 2009"
          year = 2009
        when "coaching/ethics_children.doc"
          description = "Child Policy, proposal, January 2004"
          year = 2004
        when "coaching/karolyi09.doc"
          description = "Notice of training by Tibor Karolyi, 2009"
          year = 2009
        when "coaching/Moves_for_Life_2011.pdf"
          description = "MovesForLife, visionary document, 2011"
          year = 2011
        when "coaching/training_seminars_2013.pdf"
          description = "Training seminars (TRG-ICU), 2013"
          year = 2013
        when /\Act\/CT-(\d+)\.(pdf|pgn)\z/
          description = "Chess Today ##{$1}#{$2 == 'pgn' ? ' games' : ''}"
          year = case $1.to_i
            when 1913..2114 then 2006
            when 2500       then 2007
            when 2667..2840 then 2008
            when 3052..3324 then 2009
            when 3353..3690 then 2010
            when 4000..4002 then 2011
            when 4996       then 2014
          end
        when "development/comments_received.doc"
          description = "ICU development plan (request for comments) 2010"
          year = 2010
        when "development/development_plan.doc"
          description = "ICU development plan (initiating document) 2010"
          year = 2010
        when "development/implementation_plan.xls"
          description = "ICU development plan (implementation) 2010"
          year = 2010
        when "events/2010_olympiad.pdf"
          description = "International Selection Committee, bulletin, May 2010"
          year = 2010
        when "events/Branagan_2010.pdf"
          description = "Branagan Cup entry form, 2010"
          year = 2010
        when "events/branagan_entry_2011.pdf"
          description = "Branagan Cup, Killane Shield and William Brennan Trophy entry form, 2011"
          year = 2011
        when "events/branagan_killane_brennan_rules_2011.pdf"
          description = "Branagan Cup, Killane Shield and William Brennan Trophy rules, 2011"
          year = 2011
        when "events/Brennan_2010.pdf"
          description = "William Brennan Trophy entry form, 2010"
          year = 2010
        when "events/CheckMate_Secondary_Schools_Finals_2011.pdf"
          description = "CheckMate Secondary Schools Finals, 2011"
          year = 2011
        when "events/Checkmate_Secondary_Schools_Finals_2013.pdf"
          description = "CheckMate Secondary Schools Finals, 2013"
          year = 2013
        when "events/ChessForAll_Kilkenny_2013_Jan.pdf"
          description = "ChessForAll, Kilkeeny 2013, final standings"
          year = 2013
        when "events/ChessForAll_Laois_2013_Jan.pdf"
          description = "ChessForAll, Laois 2013, final standings"
          year = 2013
        when "events/ChessZ_Finals_2011.pdf"
          description = "ChessZ Finals, 2011"
          year = 2011
        when "events/ChessZ_Mid_Ireland_Finals_2011.pdf"
          description = "ChessZ Mid-Ireland Finals, 2011"
          year = 2011
        when "events/dunl_2010_event_poster.pdf"
          description = "Dun Laoghaire Chess Festival, 2010, poster"
          year = 2010
        when "events/dunl_2010_events_programme.pdf"
          description = "Dun Laoghaire Chess Festival, 2010, programme of events (version 1)"
          year = 2010
        when "events/dunl_2010_events_programme2.pdf"
          description = "Dun Laoghaire Chess Festival, 2010, programme of events (version 2)"
          year = 2010
        when "events/dunl_2010_festival_announcement.pdf"
          description = "Dun Laoghaire, 2010, GM and IM tournament announcement"
          year = 2010
        when "events/dunl_2010_members_letter.pdf"
          description = "Dun Laoghaire, 2010, letter to members"
          year = 2010
        when "events/dunl_2010_pairings.xls"
          description = "Dun Laoghaire, 2010, pairings"
          year = 2010
        when "events/estc_2008.doc"
          description = "European Senior Team Championship 2008, Dresden, Germany, schedule"
          year = 2008
        when "events/EUYCC_regulation_2013.pdf"
          description = "European Union Youth Championship 2013, Mureck, Austia, regulations"
          year = 2013
        when "events/Irish_Juniors_2013.pdf"
          description = "Irish Junior Championships, 2013"
          year = 2013
        when "events/Irish_Primary_Schools_CheckMate_Finals_2011.pdf"
          description = "Irish Primary Schools CheckMate Finals, 2011"
          year = 2011
        when "events/Irish_Primary_Schools_Girls_League_Finals_2011.pdf"
          description = "Irish Primary Schools Girls League Finals, 2011"
          year = 2011
        when "events/Irish_Primary_Schools_League_Finals_2011.pdf"
          description = "Irish Primary Schools League Finals, 2011"
          year = 2011
        when "events/Killane_2010.pdf"
          description = "Killane Shield entry form, 2010"
          year = 2010
        when "events/LCU_Cups_2012.doc"
          description = "Branagan Cup, Killane Shield and William Brennan Trophy entry form, 2012"
          year = 2012
        when "events/Leinster_Schools_2013.xlsx"
          description = "Leinster Schools Results, 2013"
          year = 2013
        when "events/Leinster_Secondary_Finals_Mar_2012.pdf"
          description = "ChessZ Leinster Secondary Schools Finals, May 2012"
          year = 2012
        when /\Aevents\/Limerick_Monthly_(\w{3})_20(\d\d)\.pdf\z/
          description = "Limerick Monthly, #{$1}, 20#{$2}"
          year = "20#{$2}".to_i
        when "events/Mick_Germaine_Cup_2012.docx"
          description = "Mick Germaine Cup, 2012"
          year = 2012
        when /\Aevents\/Mid_Ireland_(\w+)_2011\.pdf\z/
          description = "Mid-Ireland #{$1.split('_').join(' ')} 2011"
          year = 2011
        when /\Aevents\/Munster_Junior_Championships_20(\d\d)\.pdf\z/
          description = "Munster Junior Championships 20#{$1}"
          year = "20#{$1}".to_i
        when /\Aevents\/National_Club_Champs_2013.pdf\z/
          description = "National Club Championships 2013"
          year = 2013
        when /\Aevents\/Polimac_Kilkenny_Christmas_2011.pdf\z/
          description = "Kilkenny Christmas Junior Tournament, 2011"
          year = 2011
        when /\Aevents\/sam_collins_dublin_squares.pdf\z/
          description = "Dublin Garden Squares, Sam Collins Simul, 2010"
          year = 2010
        when /\Aevents\/WYCC_2012.pdf\z/
          description = "World Youth Chess Championships 2012, Maribor, Slovenia"
          year = 2012
        when "fide/GA2008.pdf"
          description = "General Assemby Agenda, FIDE Congress, 2008, Dresden, Germany"
          year = 2008
        when /\Agames\/ch(\d\d)\.pgn\z/
          description = "Irish Championship 20#{$1}"
          year = "20#{$1}".to_i
        when "games/dublin_masters_2012.pgn"
          description = "Dublin Masters 2012"
          year = 2012
        when "games/dunlaoghaire10.pgn"
          description = "Dun Laoghaire Centenary 2010"
          year = 2010
        when "games/etc05.pgn"
          description = "European Team Championships 2005, Gothenberg, Sweden"
          year = 2005
        when "games/olm38.pgn"
          description = "38th Olympiad 2008, Desden, Germany"
          year = 2008
        when /\Aicj\/icj_(\d\d)(\d\d)\.pdf\z/
          month = case $2
            when "02" then "February"
            when "05" then "May"
            when "06" then "June"
            when "08" then "August"
            when "09" then "September"
            when "10" then "October"
            when "12" then "December"
          end
          description = "Irish Chess Journal, #{month} 20#{$1}"
          year = "20#{$1}".to_i
        when "icj/jcc_0706.pdf"
          description = "Junior Chess Corner, June 2007"
          year = 2007
        when "lcu/2010_Novices_League.pdf"
          description = "LCU O'Connell Cup, Novices Chess League, 2010-11"
          year = 2010
        when "lcu/AGM_Motions_2010.pdf"
          description = "Motions for 2010 LCU AGM"
          year = 2010
        when "lcu/League_Rules_2010_Draft_V2.pdf"
          description = "LCU league rules, draft version 2, June 2010"
          year = 2010
        when "lcu/LJCGP.pdf"
          description = "Leinster Junior Chess League (LJCL), Grand Prix, 2011-12"
          year = 2011
        when /\Axls\/sample\.(csv|xls|xlsx)\z/
          description = "Foreign tournament sample report (#{$1.upcase})"
          year = 2008
        when "reports/cc07.pdf"
          description = "Cork Congress 2007"
          year = 2007
        when "reports/icu_isc_glorney_2012.pdf"
          description = "ICU International Selection Committee, report, May 2012"
          year = 2012
        end
        [description, year, access]
      end
    end
  end
end
