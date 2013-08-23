module ICU
  module Legacy
    class Member
      def self.sync(force=false)
        puts "SYNC #{force ? 'yes' : 'no'}"
      end
    end
  end
end
