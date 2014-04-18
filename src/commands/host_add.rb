

command 'host install' do |c|

  c.syntax = "#{PROGRAM} host install <name>"
  c.description = "Installs the Moai host specified"
  c.option '--local', 'install under current project folder instead of in the shared location'
  c.option '--repository URL','git repository to find the host eg git://github.com/halfnelson/host-zipline-glut'
  c.option '--branch REF','git ref to checkout from repository'
  c.action do |args,options|
    require 'lib/project'
    require 'lib/host'
    require "lib/helper/hosts_helper"
    name = args.first
    bail "Name is required" unless name
    options.default  :branch => 'master', :local => false
    app = MoaiCLI.new
    project = Project.new
    host_paths = [project.hosts_root,app.hosts_root]
    host = Host.find_host(name,host_paths)
    bail "a host named #{name} already exists [#{host.info.name_} (#{host.info.version_})] at #{host.path}" if host

    install_path = File.join(options.local ? project.hosts_root : app.hosts_root,name)
    HostsHelper.clone(install_path, options.repository)
    HostsHelper.checkout(install_path, options.branch)
    status "Success", "Host #{name} installed at #{install_path}"
  end
end

