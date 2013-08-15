# So bundle install is run
require "bundler/capistrano"

# Add web:enable and web:disable
require "capistrano/maintenance"

set :application, "www2.icu.ie"
role :app, application
role :web, application
role :db,  application, :primary => true

set :user, "mjo"
set :deploy_to, "/var/apps/www"
set :deploy_via, :remote_cache
set :use_sudo, false

set :scm, :git
set :repository, "git://github.com/sanichi/icu_www_app.git"
set :branch, "master"

namespace :deploy do
  desc "Do nothing on startup so we don't get a script/spin error."
  task :start do ; end

  desc "Do nothing on stop."
  task :stop do ; end

  desc "Tell Passenger to restart."
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  desc "Symlink extra configs and folders."
  task :symlink_extras do
    %w{database app_config}.each do |yml|
      run "ln -nfs #{shared_path}/config/#{yml}.yml #{release_path}/config/#{yml}.yml"
    end
  end

  desc "Setup shared directory."
  task :setup_shared do
    run "mkdir #{shared_path}/config"
    put File.read("config/examples/database.yml"), "#{shared_path}/config/database.yml"
    put File.read("config/examples/app_config.yml"), "#{shared_path}/config/app_config.yml"
    puts "Now edit the config files in #{shared_path}."
  end

  desc "Make sure there is something to deploy."
  task :check_revision, roles: :web do
    unless `git rev-parse HEAD` == `git rev-parse origin/master`
      puts "WARNING: HEAD is not the same as origin/master"
      puts "Run `git push` to sync changes."
      exit
    end
  end

  namespace :web do
    # Adapt the version in capistarno-maintenance for HAML.
    desc "Present a maintenance page to visitors using REASON and BACK enviroment variables (or defaults)."
    task :disable, roles: :web, except: { no_release: true } do
      require "haml"
      file = "#{shared_path}/system/#{maintenance_basename}.html"
      on_rollback { run "rm #{file}" }

      template = File.read("app/views/layouts/maintenance.html.haml")
      engine = Haml::Engine.new(template, format: :html5, attr_wrapper: '"')
      reason = ENV["REASON"] || "maintenance"
      back = ENV["BACK"] || "shortly"
      page = engine.render(binding)

      put page, file, mode: 0644
    end
  end
end

before "deploy", "deploy:check_revision"
after "deploy", "deploy:cleanup"
after "deploy:setup", "deploy:setup_shared"
before "deploy:assets:precompile", "deploy:symlink_extras"
