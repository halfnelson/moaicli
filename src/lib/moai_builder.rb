require 'lib/helper/cmake_helper'


module MoaiBuilder

  #common for all host platforms
  class BaseBuilder

    include CMakeHelper

    attr_accessor :sdk, :app, :build_dir, :config, :options

    def lib_build_dir
      File.join(build_dir,'libmoai')
    end

    def plugin_in_project(plugin)
      File.join(config.project.plugin_path,plugin)
    end

    def plugin_in_shared(plugin)
      File.join(app.plugin_path,plugin)
    end

    def find_plugin_path(plugin)
      Dir.exists? plugin_in_project(plugin) ? plugin_in_project(plugin) : plugin_in_shared(plugin)
    end

    def initialize(app,build_config,options)
      @options = options
      @config = build_config
      @sdk = build_config.sdk
      @app = app
      @build_dir = build_config.build_dir
      @cmake = config_cmake()
    end

    def cmake_context
      { plugins: config.plugins || [] }
    end

    def cmake_cache_exists?
      File.exists?(File.join(cmake_build_dir,'CMakeCache.txt'))
    end

    def build_type
      options.release ? 'Release' : 'Debug'
    end

    def create_cmake_build(cmake_params)
      #skip this if it has been already done.
      return if cmake_cache_exists? && !options.force # && !config.config_has_changed?

      params = cmake_params ? cmake_params.dup: []
      #our three required params
      params.push(cmake_platform_params)
      params.push("-DCMAKE_BUILD_TYPE=#{build_type}")
      params.push("-DPLUGIN_DIR='#{config.project.plugin_path}'")
      params.push("-DLIBMOAI_DIR='#{lib_build_dir}'")
      params.push("-DBUILD_DIR='#{build_dir}'")
      params.push("-DSDK_DIR='#{sdk.sdk_path}'")
      params.push("-DSRC_DIR='#{config.project.src_path}'")
      params << config.host.cmake_path

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
      #copy our libmoai and plugin cmake file
      directory app.libmoai_template_path, lib_build_dir, cmake_context #todo avoid modifications if not changed
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



  end

  class WindowsBuilder < BaseBuilder
    require 'lib/helper/mingw_helper'
    include MingwHelper
    def initialize(app,build_config,options)
      super(app,build_config,options)
      bail "Building for Windows currently requires Windows" unless app.platform.type == :windows
      @mingw = config_mingw

    end

    def cmake_platform_define
      'BUILD_WINDOWS'
    end

    def cmake_makefile_type
      'MinGW Makefiles'
    end

    def cmake_platform_params
      "-G \"#{cmake_makefile_type}\" -D#{cmake_platform_define}=true"
    end
  end

  class OSXBuilder < BaseBuilder
    def initialize(app,build_config,options)
      super(app,build_config,options)
      bail "Building for OSX requires MacOSX" unless app.platform.type == :macosx
    end

    def cmake_platform_define
      'BUILD_OSX'
    end

    def cmake_makefile_type
      'Unix Makefiles'
    end

    def cmake_platform_params
      "-G \"#{cmake_makefile_type}\" -D#{cmake_platform_define}=true"
    end
  end

  class LinuxBuilder < BaseBuilder
    def initialize(app,build_config,options)
      super(app,build_config,options)
      bail "Building for Linux requires linux" unless app.platform.type == :linux
    end

    def cmake_platform_define
      'BUILD_LINUX'
    end

    def cmake_makefile_type
      'Unix Makefiles'
    end

    def cmake_platform_params
      "-G \"#{cmake_makefile_type}\" -D#{cmake_platform_define}=true"
    end
  end

  class AndroidBuilder < BaseBuilder
    require 'lib/helper/android_sdk_helper'
    include AndroidSdkHelper

    def initialize(app,build_config,options)
      super(app,build_config,options)
      @ndk = config_android_ndk
    end

    def cmake_platform_define
      'BUILD_ANDROID'
    end

    def cmake_toolchain_file
      File.join(File.join(MOAICLI_ROOT,'config'),'android-cmake','android.toolchain.cmake')
    end

    def cmake_platform_params
      params = []
      params.push "-D#{cmake_platform_define}=true"
      params.push "-DCMAKE_TOOLCHAIN_FILE='#{cmake_toolchain_file}'"
      params.push "-DLIBRARY_OUTPUT_PATH_ROOT='#{cmake_build_dir}'"
      #ndk def
      params.push "-DANDROID_NDK=#{@ndk.ndk_location}"
      if app.platform.type == :windows
        params.push %Q{-G "MinGW Makefiles"}
        params.push %Q{-DCMAKE_MAKE_PROGRAM="#{File.join(@ndk.ndk_prebuilt_bin,'make.exe')}"}
      end

      params.join(" ")
    end
  end




  class IOSBuilder < BaseBuilder
    require "lib/helper/ios_sdk_helper"
    include IOSSdkHelper

    def initialize(app,build_config,options)
      super(app,build_config,options)
      bail "Building for IOS requires MacOSX" unless app.platform.type == :macosx
    end

    def cmake_platform_define
      'BUILD_IOS'
    end

    def cmake_makefile_type
      'Xcode'
    end

    def cmake_parallel_param
      "" # "-parallelizeTargets"
    end


    

    def create_cmake_root
      super
      #create a CMakeLists.txt with our src folder contents inside
      src = config.project.src_path
      files = Dir.glob(File.join(src,'**','*'))
      cmake_content = %Q[
          cmake_minimum_required ( VERSION 2.8.5 )
          project ( moai-project-res )

          set ( PROJECT_RESOURCES
             #{files.map {|f| '"'+f+'"' } * "\n" }
             PARENT_SCOPE
          )
      ]
      res_dir = File.join(build_dir,'resources')
      FileUtils.mkdir_p(res_dir)
      IO.write(File.join(res_dir,'CMakeLists.txt'),cmake_content)
    end


    def cmake_toolchain_file
      File.join(File.join(MOAICLI_ROOT,'config'),'ios-cmake','toolchain','iOS.cmake')
    end

    def cmake_ios_platform
       'OS'
    end

    def sdk_platform_path
       iphone_platform_path
    end

    def cmake_platform_params
      "-G \"#{cmake_makefile_type}\" -D#{cmake_platform_define}=true -DIOS_PLATFORM=#{cmake_ios_platform} -DCMAKE_TOOLCHAIN_FILE='#{cmake_toolchain_file}' -DCMAKE_IOS_DEVELOPER_ROOT=\"#{sdk_platform_path}\""
    end
  end


  class IOSSimulatorBuilder < IOSBuilder

    def initialize(app,build_config,options)
      super(app,build_config,options)
      bail "Building for IOS requires macosx" unless app.platform.type == :macosx
    end

    def cmake_ios_platform
      'SIMULATOR'
    end

    def sdk_platform_path
      iphone_simulator_platform_path
    end
  end

  class HtmlBuilder < BaseBuilder
    require 'lib/helper/emscripten_helper'


    require 'lib/helper/mingw_helper'
    include MingwHelper

    attr_accessor :emscripten
    def initialize(app,build_config,options)
      super(app,build_config,options)
      @emscripten = EmscriptenHelper.config_emscripten(app)
      if os == :windows
        @mingw = config_mingw
        #sdk.subst! - maps a drive letter to the sdk path to help compile
      end

    end

    def cmake_platform_define
      'BUILD_HTML'
    end

    def cmake_makefile_type
      case os
        when :windows
          'MinGW Makefiles'
        else
          'Unix Makefiles'
      end
    end

    def cmake_platform_params
      params = []
      params.push "-G \"#{cmake_makefile_type}\""
      params.push "-D#{cmake_platform_define}=true"
      params.push "-DCMAKE_TOOLCHAIN_FILE='#{emscripten.cmake_toolchain}'"
      params.push  "-DEMSCRIPTEN_ROOT_PATH='#{emscripten.home}'"

      params.join(" ")
    end
  end


  def get_builder(app,build_config,options)
      case build_config.host.type.to_sym
        when :windows
           WindowsBuilder.new(app,build_config,options)
        when :android
           AndroidBuilder.new(app,build_config,options)
        when :ios
           IOSBuilder.new(app,build_config,options)
        when :ios_simulator
          IOSSimulatorBuilder.new(app,build_config,options)
        when :osx
           OSXBuilder.new(app,build_config,options)
        when :linux
           LinuxBuilder.new(app,build_config,options)
        when :html
           HtmlBuilder.new(app,build_config,options)
         else
           bail "No build rules defined for #{build_config.host.type}"
       end
  end
end
