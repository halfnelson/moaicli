require 'lib/builder_task'
require 'lib/project'
require 'lib/host'
require 'lib/helper/hosts_helper'

command :start do |c|
  c.syntax = "#{PROGRAM} start <host_name>"
  c.description = "Runs the moai project in the current folder on the selected host"
  c.summary = "Runs the specified host"
  c.option '--platform <platform>', String, 'use the specified platform'
  c.action do |args,options|

    host_name = args.first
    bail "host_name is required" unless host_name
    app = MoaiCLI.new
    options.default :platform => nil, :simulator=> true
    project = Project.new
    host_paths =   [project.hosts_root,app.hosts_root]
    host = Host.find_host(host_name,host_paths)
    bail "Host #{host_name} was not found in among the installed hosts\nHosts:\n#{HostsHelper.list_hosts(host_paths)}" unless host
    task = BuilderTask.new(app, project, host, options)
    status "Build", "Invoking host specific start task"
    task.build
    task.build_config.update_digest
    task.start
  end
end

