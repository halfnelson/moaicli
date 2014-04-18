command 'sdk update' do |c|
  c.syntax = "#{PROGRAM} sdk update <HOST>"
  c.description = "updates the configured sdk for HOST from its origin (git pull)"
  c.action do |args,options|
    require 'lib/builder_task'
    require 'lib/project'
    require 'lib/host'
    require 'lib/helper/hosts_helper'
    host_name = args.first
    bail "host_name is required" unless host_name
    app = MoaiCLI.new
    project = Project.new
    host_paths =   [project.hosts_root,app.hosts_root]
    host = Host.find_host(host_name,host_paths)
    bail "Host #{host_name} was not found in among the installed hosts\nHosts:\n#{list_hosts(host_paths)}" unless host
    build_config = BuildConfig.new(app,project,host,'debug')
    sdk = build_config.sdk
    status "Update","Updating SDK from #{sdk.git_tag} at #{sdk.git_src}"
    sdk.update
  end
end

