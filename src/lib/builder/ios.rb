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


  def cmake_extra_build_params
    "#{sdk_param} #{arch_param}"
  end

  def arch_param
    if simulator?
      "-arch i386"
    else
      "-arch armv7"
    end
  end

  def sdk_param
    if simulator?
      "-sdk iphonesimulator"
    else
      "-sdk iphoneos"
    end
  end

  def simulator?
    config.host.type == 'ios_simulator'
  end


  def create_cmake_root
    super
    #create a CMakeLists.txt with our src folder contents inside
    src = config.project.src_path
    files = Dir.glob(File.join(src,'*'))
    cmake_content = %Q[
          cmake_minimum_required ( VERSION 2.8.5 )
          project ( moai-project-res )

          set ( PROJECT_RESOURCES
             #{files.map {|f| '"'+f+'"' } * "\n" }
             PARENT_SCOPE
          )
      ]
    res_dir = File.join(build_dir,'bin','bundle_res')
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
    "-G \"#{cmake_makefile_type}\" -D#{cmake_platform_define}=true"
  end
end