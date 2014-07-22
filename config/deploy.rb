set :application, "icu_www_app"

set :scm, :git
set :repo_url, "git://github.com/sanichi/icu_www_app.git"
set :branch, "master"

set :deploy_to, "/var/apps/www"

set :linked_files, %w{config/database.yml config/secrets.yml}
set :linked_dirs, %w{log tmp/pids public/system public/webalizer}  # capistrano/rails adds public/assets

set :maintenance_file, "public/system/maintenance.html"

set :log_level, :info

# set :format, :pretty
# set :pty, true
# set :keep_releases, 5

# namespace :deploy do
#
#   desc 'Restart application'
#   task :restart do
#     on roles(:app), in: :sequence, wait: 5 do
#       # Your restart mechanism here, for example:
#       # execute :touch, release_path.join('tmp/restart.txt')
#     end
#   end
#
#   after :restart, :clear_cache do
#     on roles(:web), in: :groups, limit: 3, wait: 10 do
#       # Here we can do anything such as:
#       # within release_path do
#       #   execute :rake, 'cache:clear'
#       # end
#     end
#   end
#
#   after :finishing, 'deploy:cleanup'
#
# end
