#
# Cookbook Name:: Deploy Xeepic Server
# Recipe:: default
#
# Copyright 2015, XEEPIC
#
# All rights reserved - Do Not Redistribute

include_recipe 'deploy'

puts "------------------------------TEST OUTPUT!!!!!!!!!!------------------------"
puts "-"
puts "-"

puts "node:deploy::"
puts node[:deploy]
=begin
puts "params::"
puts params

puts "opsworks::"
puts node["opsworks"]
=end
puts "-"
puts "-"
puts "--------------------------- END END END TEST OUTPUT!!!!!!!!!! ---------------"

node[:deploy].each do |application, deploy|
  if application == 'xeepic_server' || node[:deploy].count == 1
    directory "#{deploy[:deploy_to]}" do
      group deploy[:group]
      owner deploy[:user]
      mode "0775"
      action :create
      recursive true
    end
  
    if deploy[:scm]
      ensure_scm_package_installed(deploy[:scm][:scm_type])
  
      prepare_git_checkouts(
        :user => deploy[:user],
        :group => deploy[:group],
        :home => deploy[:home],
        :ssh_key => deploy[:scm][:ssh_key]
      ) if deploy[:scm][:scm_type].to_s == 'git'
    end
  
    deploy = node[:deploy][application]
  
    ruby_block "change HOME to #{deploy[:home]} for source checkout" do
      block do
        ENV['HOME'] = "#{deploy[:home]}"
      end
    end
  
    # setup deployment & checkout
    if deploy[:scm] && deploy[:scm][:scm_type] != 'other'
      Chef::Log.debug("Checking out source code of application #{application} with type #{deploy[:application_type]}")
      deploy deploy[:deploy_to] do
        provider Chef::Provider::Deploy.const_get(deploy[:chef_provider])
        keep_releases deploy[:keep_releases]
        repository deploy[:scm][:repository]
        user deploy[:user]
        group deploy[:group]
        revision deploy[:scm][:revision]
        migrate deploy[:migrate]
        migration_command deploy[:migrate_command]
        environment deploy[:environment].to_hash
        purge_before_symlink(deploy[:purge_before_symlink]) unless deploy[:purge_before_symlink].nil?
        create_dirs_before_symlink(deploy[:create_dirs_before_symlink])
        symlink_before_migrate(deploy[:symlink_before_migrate])
        symlinks(deploy[:symlinks]) unless deploy[:symlinks].nil?
        action deploy[:action]
  
        scm_provider :git
        enable_submodules deploy[:enable_submodules]
        shallow_clone deploy[:shallow_clone]
  
        before_migrate do
          link_tempfiles_to_current_release
          
          if deploy[:auto_npm_install_on_deploy]
            OpsWorks::NodejsConfiguration.npm_install(application, node[:deploy][application], release_path, node[:opsworks_nodejs][:npm_install_options])
            
            execute "Setup Xeepic Server" do
              user "root"
              command "cd #{release_path} && npm run setup"
            end
          end
        end
        
        before_restart do
          execute "Stop Xeepic Service" do
            user "root"
            command "cd #{current_path} && forever stop xeepic_prod"
          end
        end
        
        after_restart do
          execute "Start Xeepic Service" do
            user "root"
            command "cd #{current_path} && forever start xeepic_prod"
          end
        end
        
      end
    end
  end
end
puts "--------------------------- DEPLOY!!!! ---------------"
