#common for all host platforms

require 'lib/helper/cmake_helper'

class BaseBuilder

  include CMakeHelper

  attr_accessor :sdk, :app, :build_dir, :config, :options

  def initialize(app,build_config,options)
    @options = options
    @config = build_config
    @sdk = build_config.sdk
    @app = app
    @build_dir = build_config.build_dir
    @cmake = config_cmake()
  end

  def cmake_output_dir
    output_base =  File.join(config.build_dir,'bin')
    File.expand_path((config.host.output_directory or "host-custom") ,output_base)
  end

  def cmake_output_bin
    config.host.output_name or "moai"
  end

  def cmake_output
    File.join(cmake_output_dir,cmake_output_bin)
  end

  def cmake_target
    config.host.target or "moai"
  end

  def directory_with_config(src,dest)
    directory(src,dest,config)
  end

  def file_content_with_config(src)
    file_content(src,config)
  end

  def cmake_cache_exists?
    File.exists?(File.join(cmake_build_dir,'CMakeCache.txt'))
  end

  def build_type
    options.release ? 'Release' : 'Debug'
  end

  def create_cmake_build(cmake_params)
    #skip this if it has been already done.
    return if cmake_cache_exists? && !config.config_has_changed?

    params = cmake_params ? cmake_params.dup: []

    #our three required params
    params.push(cmake_platform_params)
    params.push("-DCMAKE_BUILD_TYPE=#{build_type}")

    if Dir.exists?(config.project.plugin_path) and Dir.entries(config.project.plugin_path).reject { |d| d == "." || d == ".."}.any?
      params.push("-DPLUGIN_DIR='#{config.project.plugin_path}'")
    end

    params.push("-DCUSTOM_HOST='#{config.host.cmake_path}'") if config.host.has_cmake_file?

    params << "\"#{File.join(sdk.sdk_path,'cmake')}\""

    FileUtils.chdir(cmake_build_dir) do
      status "Configuring", "Configuring Build Environment"
      result = cmake_command(params.join(" "))
      bail "Cmake failed to create makefiles  : exitcode #{result}" unless result
    end
  end

  def processor_count
    java.lang.Runtime.getRuntime.availableProcessors
  end

  def launch_cmake_build(target)
    FileUtils.chdir(cmake_build_dir) do
      status "Compiling", "Building with CMake"
      result = cmake_command("--build . --target #{target} --  #{cmake_parallel_param} #{cmake_extra_build_params}")
      bail "Cmake command failed --build .  : exitcode #{result}" unless result
    end
  end

  def create_cmake_root
    #per plaform
  end

  def cmake_build_dir
    File.join(build_dir,'bin')
  end

  def create_build_dir
    FileUtils.mkdir_p cmake_build_dir
  end

  def cmake_command(params)
    status "Building With", params
    system "cmake #{params}"
  end

  def build_cmake(target, cmake_params)
    create_cmake_root
    create_build_dir

    create_cmake_build(cmake_params)
    launch_cmake_build(target)
  end

  def cmake_parallel_param
    "-j#{processor_count}"
  end

  def cmake_extra_build_params
    ""
  end

  def cmake_platform_params
    #per platform
  end

  def do_build_moai(target, params=[])
    full_params = params.dup
    modules = config.modules || []

    modules.each do |mod, enabled|
      if enabled
        full_params << "-DMOAI_#{mod.upcase}=1"
      end
    end

    plugins = config.plugins || []
    plugins.each do |plugin, enabled|
      if enabled
        full_params << "-DPLUGIN_#{plugin.upcase}=1"
      end
    end

    build_cmake(target,full_params)
  end

  def build_moai(target,output,params=[])
    if options.force || !File.exists?(output) || config.config_has_changed?
      if options.force
        status "Build","Forced rebuild of LibMoai"
      end
      if config.config_has_changed?
        status "Build","Config has changed. Rebuilding"
      end

      unless File.exists?(output)
        status "Build","#{File.basename(output)} not found. Rebuilding"
      end

      do_build_moai(target,params)
    else
      status "Build", "Skipping cmake build. No config changes detected"
    end
  end


  def build
    #abstract
    status "Build", "building host to #{config.project.relative_path(config.build_dir)}"
    platform_build
    config.update_digest
  end

  def platform_build
    #per platform
  end
end