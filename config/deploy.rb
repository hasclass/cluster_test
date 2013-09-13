require 'bundler/capistrano'
require 'capistrano-unicorn'
require "delayed/recipes"

set :application, "cluster"
set :repository,  "git@github.com:hasclass/cluster_test.git"
set :branch, "master"

[
  "ec2-122-248-196-243.ap-southeast-1.compute.amazonaws.com",
  "ec2-46-137-199-249.ap-southeast-1.compute.amazonaws.com"
].each do |standalone|
  role :web, standalone                          # Your HTTP server, Apache/etc
  role :app, standalone                          # This may be the same as your `Web` server
  role :db,  standalone, :primary => true # This is where Rails migrations will run
end
# role :db,  "your slave db-server here"

set :use_sudo,          false
set :scm,               :git
set :deploy_via, :remote_cache

set :user,              "deploy"
set :deploy_to,         "/opt/apps/cluster"
set :rails_env,         "production"
set :app_context,       "/"

set :ssh_options, {
  :forward_agent => true,
  :keys => %w(~/.ssh/deploy)
}

namespace :deploy do
  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/database.yml #{release_path}/config/database.yml"
  end
end
after 'deploy:update_code', 'deploy:symlink_shared'
after "deploy:update_code", "deploy:migrate"
after "deploy:restart",     "deploy:cleanup"


namespace :unicorn do
  desc "Zero-downtime restart of Unicorn"
  task :restart, except: { no_release: true } do
    run "kill -s USR2 `cat /opt/apps/cluster/current/tmp/pids/unicorn.cluster.pid`"
  end

  desc "Start unicorn"
  task :start, except: { no_release: true } do
    run "cd #{current_path} ; bundle exec unicorn_rails -c config/unicorn.rb -D"
  end

  desc "Stop unicorn"
  task :stop, except: { no_release: true } do
    run "kill -s QUIT `cat /opt/apps/cluster/current/tmp/pids/unicorn.cluster.pid`"
  end
end

after "deploy:restart", "unicorn:restart"
# after 'deploy:restart', 'unicorn:reload'    # app IS NOT preloaded
# after 'deploy:restart', 'unicorn:restart'   # app preloaded
after 'deploy:restart', 'unicorn:restart' # before_fork hook implemented (zero downtime deployments)
