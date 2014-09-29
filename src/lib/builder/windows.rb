require 'lib/builder/desktop'
class WindowsBuilder < DesktopBuilder

  def initialize(app,build_config,options)
    super(app,build_config,options)
    bail "Building for Windows currently requires Windows" unless app.platform.type == :windows
  end

  def cmake_makefile_type
    case config.visual_studio_version
      when '2014', '13'
        'Visual Studio 13'
      when '2013','12'
        'Visual Studio 12'
      when '2012','11'
        'Visual Studio 11'
      when '2010','10'
        'Visual Studio 10'
      when '9', '2008'
        'Visual Studio 9'
      else
        'Visual Studio 11'
    end
  end

  def cmake_parallel_param
    "/m"
  end

  def cmake_target
    config.host.target or "ALL_BUILD"
  end

  def cmake_platform_params
    "-G \"#{cmake_makefile_type}\" -DBUILD_WINDOWS=true"
  end

  def cmake_output_bin
     super + ".exe"
  end

  def cmake_output_dir
    File.join(super, build_type)
  end

end

