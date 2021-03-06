require 'lib/helper/hosts_helper'

command 'host list' do |c|
  c.syntax = "#{PROGRAM} host list"
  c.description = "lists installed Moai hosts"
  c.action do |args,options|
    app = MoaiCLI.new
    project = Project.new
    host_paths =   [project.hosts_root,app.hosts_root]
    puts HostsHelper.list_hosts(host_paths)
  end
end

