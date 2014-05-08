module ICU
  module Legacy
    class Image
      include Database

      MAP = {
        img_id:          :id,
        img_type:        nil,
        img_size:        nil,
        img_width:       nil,
        img_height:      nil,
        img_description: :caption,
        img_year:        :year,
        img_mem_id:      :user_id,
      }

      def synchronize
        puts "total image records (before): #{::Image.count}"
        old_count, new_count, upd_count, problems = 0, 0, 0, 0
        @path = tmp_directory
        old_database.query("SELECT #{MAP.keys.join(", ")} FROM images ORDER BY img_id").each do |old_image|
          old_count += 1
          ext_image = ::Image.find_by(id: old_image[:img_id])
          action = action_required(old_image, ext_image)
          unless action == :none
            ok = create_image(old_image, ext_image, action)
            if ok
              if ext_image
                upd_count += 1
              else
                new_count += 1
              end
            else
              problems += 1
            end
          end
        end
        puts "old image records processed: #{old_count}"
        puts "new image records created: #{new_count}"
        puts "new image records updated: #{upd_count}"
        puts "problems: #{problems}"
        puts "total image records (after): #{::Image.count}"
      end

      private

      def tmp_directory
        path = Rails.root + "tmp" + "www1" + "images"
        FileUtils.mkdir_p path
        path
      end

      def action_required(old, ext)
        case
        when !ext
          :full
        when ext.data_file_size == old[:img_size] && ext.caption == old[:img_description] && ext.year == old[:img_year]
          :none
        when ext.data_file_size == old[:img_size]
          :meta
        else
          :full
        end
      end

      def create_image(old_image, ext_image, action)
        params = MAP.each_with_object({}) do |(old_attr, new_attr), new_image|
          if new_attr
            new_image[new_attr] = old_image[old_attr]
          end
        end
        params[:source] = "www1"
        begin
          params[:data] = get_old_image_data(old_image) unless action == :meta
          if ext_image
            id = params.delete(:id)
            params.each { |k,v| ext_image.send("#{k}=", v) }
            ext_image.save!
            puts "updated image #{id}"
          else
            ::Image.create!(params)
            puts "created image #{params[:id]}"
          end
          true
        rescue => e
          report_error "could not create/update image ID #{params[:id]}: #{e.message}"
          false
        end
      end

      def get_old_image_data(old)
        file = "#{old[:img_id]}.#{old[:img_type]}"
        path = @path + file
        File.delete(path) if File.exists?(path)
        `wget http://www.icu.ie/images/db/#{file} --quiet -O #{path}`
        raise "#{path} doesn't exist" unless File.exist?(path)
        File.new(path)
      end

      def report_error(msg)
        puts "ERROR: #{msg}"
      end
    end
  end
end
