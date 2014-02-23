require 'lib/builder/desktop'
class WindowsBuilder < DesktopBuilder
  require 'lib/helper/mingw_helper'

  def initialize(app,build_config,options)
    super(app,build_config,options)
    bail "Building for Windows currently requires Windows" unless app.platform.type == :windows
    MingwHelper.config_mingw(app)
  end

  def cmake_makefile_type
    'MinGW Makefiles'
  end

  def cmake_platform_params
    "-G \"#{cmake_makefile_type}\" -DBUILD_WINDOWS=true"
  end

  def cmake_output_bin
     super + ".exe"
  end


end