require 'lib/helper/moaisdk_helper'
require 'lib/moai_builder'
require 'lib/build_config'
class BuilderTask
  attr_accessor :app, :build_config, :options, :project,:host


  include MoaiSdkHelper
  include MoaiBuilder

  def initialize(app, project, host, options)
    @app = app
    @options = options
    @project = project
    @host = host
    @build_config = BuildConfig.new(app,project,host,(options.release ? 'release': 'debug'))
    require host.build_file
    self.class.send :include, BuildFile
    if options.clean
      status "Clean", "Removing old build files"
      FileUtils.rm_rf(build_config.build_dir)
    end
  end




  def build_env
    builder = get_builder(app,build_config,options)
    status "ENV", "setup env"
    require 'childprocess.rb'

    status "ENV", "Launching shell with dev environment"
    if os == :windows
      cmd = ENV['ComSpec']
    else
      cmd = 'bash'
    end
    process = ChildProcess.build(cmd)

# start the process
    process.start
    process.wait
    status "ENV","Back at your old boring useless shell"
  end


  def build_cmake(target,params)
    builder = get_builder(app,build_config,options)
    builder.build_cmake(target,params)
  end



  def update_build_digest
    build_config.update_digest
  end
end