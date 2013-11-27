namespace :bootswatch do
  desc "Update the bootstrap themes"
  task :update => :environment do |task|
    User::THEMES.each do |theme|
      unless theme == "Bootstrap"
        theme.downcase!
        source = "http://bootswatch.com/#{theme}/bootstrap.min.css"
        target = "app/assets/stylesheets/#{theme}.min.css"
        sh "wget #{source} -q -O #{target}"
      end
    end
  end
end
