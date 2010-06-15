# Modified capistrano recipe, based on the standard 'deploy' recipe
# provided by capistrano but without the Rails-specific dependencies

set :stages, %w(staging production)
set :default_stage, "staging"
require "capistrano/ext/multistage"

# Set some globals
default_run_options[:pty] = true
set :application, "<%= name %>"

# Deployment
set :deploy_to, "/svc/#{application}"
#set :user, 'someone'

# Get repo configuration
set :repository, "git@github.com:yourname/#{application}.git"
set :scm, "git"
set :branch, "master"
set :deploy_via, :remote_cache
set :git_enable_submodules, 1

# No sudo
set :use_sudo, false

# File list in the config_files setting will be copied from the
# 'deploy_to' directory into config, overwriting files from the repo
# with the same name
set :config_files, %w{}

# List any work directories here that you need persisted between
# deployments. They are created in 'deploy_to'/shared and symlinked
# into the root directory of the deployment.
set :shared_children, %w{log tmp}

# Record our dependencies
unless File.directory?( "#{DaemonKit.root}/vendor/daemon_kit" )
  depend :remote, :gem, "daemon-kit", ">=#{DaemonKit::VERSION}"
end

# Hook into capistrano's events
before "deploy:update_code", "deploy:check"

# Create some tasks related to deployment
namespace :deploy do

  desc "Get the current revision of the deployed code"
  task :get_current_version do
    run "cat #{current_path}/REVISION" do |ch, stream, out|
      puts "Current revision: " + out.chomp
    end
  end
end
