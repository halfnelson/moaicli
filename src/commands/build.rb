#require 'lib/builder_task'





command :build do |c|

  c.syntax = "#{PROGRAM} build <host>"
  c.description = "Builds the project for a host and places it in the distribute folder"
  c.summary = "Builds the project for a platform and host"
  c.option '--platform <platform>', String, 'Build the host for the specified supported platform'
  c.option '--force', 'Force rebuild'
  c.option '--clean', 'Remove all generated build files before building'
  c.option '--release', 'Make a release build (default is debug)'
  c.action do |args,options|
    require 'lib/helper/hosts_helper'
    require 'lib/moai_builder'
    host_name = args.first
    bail "host_name is required" unless host_name
    app = MoaiCLI.new
    options.default  :force => false, :simulator => false, :release => false, :platform => nil, :clean =>false

    project = Project.new
    host_paths =   [project.hosts_root,app.hosts_root]
    host = Host.find_host(host_name,host_paths)
    bail "Host #{host_name} was not found in among the installed hosts\nHosts:\n#{HostsHelper.list_hosts(host_paths)}" unless host

    #set platform
    host.set_platform(options.platform)

    #create build config
    build_config = BuildConfig.new(app,project,host,(options.release ? 'release': 'debug'))

    #clean if needed
    if options.clean
      status "Clean", "Removing old build files"
      FileUtils.rm_rf(build_config.build_dir)
    end

    #build
    builder = MoaiBuilder.get_builder(app,build_config,options)
    status "Build", "Invoking host specific build task"
    builder.build
  end
end


command :env do |c|
  c.syntax = "#{PROGRAM} env <host>"
  c.description = "dumps to a shell for building host"
  c.summary = "shell with env setup for building host"
  c.option '--platform <platform>', String, 'Build the host for the specified supported platform'
  c.action do |args,options|
    host_name = args.first
    bail "host_name is required" unless host_name
    app = MoaiCLI.new
    options.default  :platform => nil

    project = Project.new
    host_paths =   [project.hosts_root,app.hosts_root]
    host = Host.find_host(host_name,host_paths)
    bail "Host #{host_name} was not found in among the installed hosts\nHosts:\n#{HostsHelper.list_hosts(host_paths)}" unless host

    #set platform
    host.set_platform(options.platform)

    task = BuilderTask.new(app, project, host, options)
    status "Shell", "Invoking platform build shell"
    task.build_env

  end
end












