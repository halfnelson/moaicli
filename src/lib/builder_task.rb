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



  def directory_with_config(src,dest)
    directory(src,dest,build_config)
  end

  def file_content_with_config(src)
    file_content(src,build_config)
  end

  def build_env
    builder = get_builder(app,build_config,options)
    status "ENV", "setup env"
    if system('c:\windows\system32\cmd.exe')
      status "ENV", "env was ok"
    end
    status "ENV", "env closed"
  end


  def build_cmake(target,params)
    builder = get_builder(app,build_config,options)
    builder.build_cmake(target,params)
  end


  def do_build_moai(target,modules, params=[])
    full_params = params.dup
    modules.each do |mod, enabled|
      if enabled
        full_params << "-DMOAI_#{mod.upcase}=1"
      end
    end
    build_cmake(target,full_params)
  end

  def build_moai(target,modules,output,params=[])
    if options.force || !File.exists?(output) || build_config.config_has_changed?
      if options.force
        status "Build","Forced rebuild of LibMoai"
      end
      if build_config.config_has_changed?
        status "Build","Config has changed. Rebuilding"
      end

      unless File.exists?(output)
        status "Build","#{File.basename(output)} not found. Rebuilding"
      end
      do_build_moai(target,modules,params)
    else
      status "Build", "Skipping cmake build. No config changes detected"
    end
  end

  def update_build_digest
    build_config.update_digest
  end
end